import pandas as pd
from openpyxl import load_workbook
from openpyxl.styles import Font, PatternFill, Alignment
import os
import tkinter as tk
from tkinter import simpledialog
from config import EXCEL_FAJLOK, OUTPUT_MAPPAK


# Fajl eleresi utja - config fajlban van
EXCEL_PATH = EXCEL_FAJLOK["EXCEL_DATA4"]

def szett_koltseg(szettszam):
    print(f"Adatok betoltese...")
    
    # Lapok beolvasasa
    full_lista = pd.read_excel(EXCEL_PATH, sheet_name="MAIN_DATA")
    szerszamlista = pd.read_excel(EXCEL_PATH, sheet_name="TOOL_LIST")
    arlista = pd.read_excel(EXCEL_PATH, sheet_name="PRICE_LIST")

    # Szures szettszamra
    # szett = full_lista[full_lista["szett_azonosito"] == szettszam].copy()    #string formatum
    szett = full_lista[full_lista["szett_azonosito"].astype(str) == str(szettszam)].copy()
    
    if szett.empty:
        print(f"Nem talalhato szettszam: {szettszam}")
        return

    print(f"Talalt sorok: {len(szett)} db")

    # SzerszamAzonosítónkent osszesiti a fogyasi aranyt
    osszesitett = szett.groupby("TOOL_ID")["CONSUMPTION_RATIO"].sum().reset_index()
    osszesitett.columns = ["TOOL_ID", "Osszes_fogyasi_arany"]

    # Join: Szerszamlista (SzerszamAzonosító -> TOOL_NUMBER + szorzo)
    osszesitett = osszesitett.merge(
        szerszamlista[["T", "TOOL_NUMBER", "COST_MULTIPLIER"]],
        left_on="TOOL_ID",
        right_on="T",
        how="left"
    )

    # Join: Arlista (TOOL_NUMBER -> AVG_PRICE)
    osszesitett = osszesitett.merge(
        arlista[["TOOL2", "AVG_PRICE"]],
        left_on="TOOL_NUMBER",
        right_on="TOOL2",
        how="left"
    )

    # Koltseg kiszamitasa
    osszesitett["Koltseg_EUR"] = (
        osszesitett["Osszes_fogyasi_arany"] * 
        osszesitett["COST_MULTIPLIER"] * 
        osszesitett["AVG_PRICE"]
    )

    # Csak a relevas oszlopok
    kimenet = osszesitett[[
        "TOOL_ID",
        "TOOL_NUMBER", 
        "Osszes_fogyasi_arany",
        "COST_MULTIPLIER",
        "AVG_PRICE",
        "Koltseg_EUR"
    ]].copy()

    # Osszesen sor
    osszesen = pd.DataFrame([{
        "TOOL_ID": "ÖSSZESEN",
        "TOOL_NUMBER": "",
        "Osszes_fogyasi_arany": "",
        "COST_MULTIPLIER": "",
        "AVG_PRICE": "",
        "Koltseg_EUR": osszesitett["Koltseg_EUR"].sum()
    }])
    
    kimenet = pd.concat([kimenet, osszesen], ignore_index=True)

    # Kimenet fajl neve
    output_path = os.path.join(OUTPUT_MAPPAK["KOLTSEG"], f"{szettszam}_koltsegek.xlsx")
 #   output_path = os.path.join(
 #      os.path.dirname(EXCEL_PATH),
 #     f"Szerszam_koltseg_{szettszam}.xlsx"
 #)

    # Mentes Excelbe
    kimenet.to_excel(output_path, index=False, sheet_name="Szerszam_koltseg")

    # Formázás
    wb = load_workbook(output_path)
    ws = wb.active

    # Fejlec formázas (kek hatter, feher bold)
    header_fill = PatternFill("solid", fgColor="1F4E79")
    header_font = Font(bold=True, color="FFFFFF")
    
    for cell in ws[1]:
        cell.fill = header_fill
        cell.font = header_font
        cell.alignment = Alignment(horizontal="center")

    # Osszesen sor formázas (sarga hatter, bold)
    last_row = ws.max_row
    summary_fill = PatternFill("solid", fgColor="FFD700")
    summary_font = Font(bold=True)
    
    for cell in ws[last_row]:
        cell.fill = summary_fill
        cell.font = summary_font

    # Oszlopszelesseg auto
    for col in ws.columns:
        max_width = max(len(str(cell.value or "")) for cell in col) + 4
        ws.column_dimensions[col[0].column_letter].width = max_width

    # EUR formatum a Koltseg oszlopra
    for cell in ws[f"F2:F{last_row}"]:
        for c in cell:
            c.number_format = '#,##0.00 "EUR"'

    wb.save(output_path)
    print(f"Kesz! Fajl mentve: {output_path}")
    print(f"Teljes szerszamkoltseg: {osszesitett['Koltseg_EUR'].sum():.2f} EUR")

if __name__ == "__main__":
    root = tk.Tk()
    root.withdraw()
    szettszam = simpledialog.askstring(
        "Azonosító", 
        "Írja be a Azonosítót:"
    )
    if szettszam:
        szett_koltseg(szettszam)