import win32com.client
import time
import os

def wait_for_box_sync(file_path, timeout=120):
    print("Box szinkron ellenorzese...")
    elapsed = 0
    last_size = -1
    
    while elapsed < timeout:
        if os.path.exists(file_path):
            current_size = os.path.getsize(file_path)
            if current_size == last_size and current_size > 0:
                print(f"Fajl kesz! Meret: {current_size/1024:.1f} KB")
                return True
            last_size = current_size
            print(f"Meg szinkronizal... {elapsed}s (meret: {current_size/1024:.1f} KB)")
        else:
            print(f"Fajl meg nem letezik... {elapsed}s")
        
        time.sleep(5)
        elapsed += 5
    
    return False

def refresh_excel(file_path):
    excel = win32com.client.Dispatch("Excel.Application")
    excel.Visible = True
    excel.DisplayAlerts = False
    excel.AskToUpdateLinks = False
    
    try:
        if not wait_for_box_sync(file_path):
            print("HIBA: Box szinkron nem fejeződött be!")
            return
        
        time.sleep(5)
        
        print(f"Megnyitas: {file_path}")
        wb = excel.Workbooks.Open(file_path, UpdateLinks=0)
        
        time.sleep(5)

        print("Kapcsolatok frissitese...")
        for conn in wb.Connections:
            try:
                print(f"  Frissites: {conn.Name}")
                try:
                    conn.OLEDBConnection.BackgroundQuery = False
                except:
                    pass
                conn.Refresh()
                time.sleep(5)
                print(f"  Kesz: {conn.Name}")
            except Exception as e:
                print(f"  Hiba ({conn.Name}): {e}")

        print("Varakozas a frissitesre...")
        time.sleep(15)

        for sheet in wb.Sheets:
            for pivot in sheet.PivotTables():
                try:
                    pivot.RefreshTable()
                except:
                    pass
        
        wb.Save()
        wb.Close()
        print("Kesz! Mentve es bezarva.\n")
        
    except Exception as e:
        print(f"Hiba: {e}")
        
    finally:
        excel.Quit()