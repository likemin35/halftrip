from pypdf import PdfReader
path = r"C:\Users\Administrator\Desktop\관광\tmp-trip1-result.pdf"
reader = PdfReader(path)
text = "\n".join((page.extract_text() or "") for page in reader.pages)
checks = ["PDF TESTER", "Alpha Stay", "123-45-67890", "Kim Host", "061-555-9999", "123 Seaside Road", "180000", "2026-04-26", "2"]
for item in checks:
    print(f"{item}: {item in text}")
