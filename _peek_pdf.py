from pypdf import PdfReader
from pathlib import Path
base = Path(r"C:\Users\Administrator\Desktop\숙박들")
for name in ["stay_confirm_haenam.pdf","stay_confirm_wando.pdf","stay_confirm_hadong.pdf","stay_confirm_pyoungchang.pdf"]:
    p = base / name
    if not p.exists():
        continue
    text = "\n".join((page.extract_text() or "") for page in PdfReader(str(p)).pages[:1])
    print("====", name, "====")
    print(text[:1500])
