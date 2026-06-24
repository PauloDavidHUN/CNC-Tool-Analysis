import os

BASE_PATH = os.path.join(os.path.expanduser("~"), "MES", "LOC1", "PROJEKT")
BASE_OUTPUT = os.path.join(os.path.expanduser("~"), "Desktop")

EXCEL_FAJLOK = {
    "EXCEL_DATA1"  : BASE_PATH + r"\data1.xlsx",
    "EXCEL_DATA2"   : BASE_PATH + r"\data2.xlsx",
    "EXCEL_DATA3"   : BASE_PATH + r"\data3.xlsx",
    "EXCEL_DATA4"    : BASE_PATH + r"\data4.xlsx",
    "EXCEL_DATA5"   : BASE_PATH + r"\data5.xlsx",
}


OUTPUT_MAPPAK = {
    "MUVELETEK"  : BASE_OUTPUT + r"\MUVELETEK",
    "KOLTSEG"    : BASE_OUTPUT + r"\KOLTSEG",
}
