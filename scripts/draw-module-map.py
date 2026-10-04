"""Render the code-grounded module map as PNG and editable SVG (no network)."""
from pathlib import Path
from html import escape
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parents[1]
out = root / 'output/tssa-validation-20261004'
out.mkdir(parents=True, exist_ok=True)
width, height = 1500, 1140
canvas = Image.new('RGB', (width, height), '#f5f7fb')
draw = ImageDraw.Draw(canvas)
font_dir = Path('C:/Windows/Fonts')
def font(size=21, bold=False):
    return ImageFont.truetype(str(font_dir / ('segoeuib.ttf' if bold else 'segoeui.ttf')), size)
svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
       '<rect width="1500" height="1140" fill="#f5f7fb"/>']
def text(x, y, value, size=21, color='#24334d', bold=False):
    draw.text((x, y), value, fill=color, font=font(size,bold))
    svg.append(f'<text x="{x}" y="{y+size}" font-family="Segoe UI, sans-serif" font-size="{size}" font-weight="{700 if bold else 400}" fill="{color}">{escape(value)}</text>')
def rect(x,y,w,h,fill='#ffffff',stroke='#d9e1ed',radius=16):
    draw.rounded_rectangle((x,y,x+w,y+h),radius=radius,fill=fill,outline=stroke,width=2)
    svg.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{radius}" fill="{fill}" stroke="{stroke}" stroke-width="2"/>')
def card(x,y,w,h,title,lines,color='#eaf1ff'):
    rect(x,y,w,h,fill=color)
    text(x+18,y+14,title,size=22,bold=True)
    for i,line in enumerate(lines): text(x+18,y+49+i*27,line,size=19)

text(38,24,'SPM-mobile · Bản đồ module',size=38,bold=True)
text(38,78,'Source hiện tại và kiểm thử ngày 04/10/2026 · Flutter + Node modular monolith',size=21,color='#60708b')
rect(38,123,1424,63,fill='#17345a',stroke='#17345a')
text(58,140,'main.dart  →  MyApp / Auth gate  →  SPM shell hoặc TssaScreen  →  Dio + Bearer  →  Node API',size=25,color='#ffffff',bold=True)

text(38,215,'DÙNG CHUNG',size=24,color='#1c5c9c',bold=True)
text(389,215,'NGHIỆP VỤ FLUTTER',size=24,color='#1c5c9c',bold=True)
text(1139,215,'BACKEND / DỮ LIỆU',size=24,color='#1c5c9c',bold=True)

card(38,262,321,135,'App + theme',['ProviderScope · auth gate','Reset route khi mất phiên','Giảm chuyển động'])
card(38,415,321,135,'Auth + session',['Login / restore / logout','Role SPM và TSSA riêng','Server kiểm tra quyền thật'])
card(38,568,321,135,'Networking',['Dio · API_BASE_URL','Bearer · 401 / account lock','Epoch cho từng phiên'])
card(38,721,321,135,'Secure storage',['Token · nháp mã hóa','Nháp TTL 24 giờ','Không cache profile offline'])
card(38,874,321,142,'Navigation + common',['SPM: IndexedStack','TSSA: trang theo tab','Form · polling · lifecycle'])

rect(389,262,719,342,fill='#ffffff')
text(410,275,'SPM · lớp và môn học',size=24,bold=True)
card(408,322,327,110,'Student',['Lớp · lịch · bài nộp','Đăng ký học'])
card(754,322,335,110,'Tutor SPM',['Sửa môn · roster · điểm','Thống kê · đánh giá · DSA'])
card(408,447,327,110,'Management',['Courses · sessions','Registrations · requests'])
card(754,447,335,110,'Admin CodePulse',['Term · classroom','Assignment · LAB'])
text(411,572,'Learning: model chung · Account: AuthSession · Health / showcase riêng',size=18,color='#60708b')

rect(389,626,719,416,fill='#ffffff')
text(410,639,'TSSA · theo báo cáo Autism',size=24,bold=True)
card(408,682,327,110,'Profiles + links',['Learner / guardian','Tutor + verification'],color='#e8f5ef')
card(754,682,335,110,'Consent + privacy',['Purpose / field / expiry','Export / delete / inventory'],color='#e8f5ef')
card(408,799,327,110,'Matching + review',['Request · hard constraints','Coordinator → family choice'],color='#e8f5ef')
card(754,799,335,110,'Bookings + sessions',['Xác nhận hai bên · đổi lịch','Notes · feedback · rematch'],color='#e8f5ef')
card(408,916,327,110,'Safety + inbox',['Case / handler / receipt','Notifications · preferences'],color='#e8f5ef')
card(754,916,335,110,'Governance + quality',['Policy · role · audit · metrics','Model card / AI kill switch'],color='#e8f5ef')

card(1139,262,323,135,'Node REST',['server / routes / auth','SPM: /api/*','TSSA: /api/v1/*'])
card(1139,415,323,135,'TSSA domain',['access · profiles','workflows · governance','Group / link / consent gates'])
card(1139,568,323,135,'Matching worker',['SQLite job + lease','Hard filters · TF-IDF / manual','AI có gate · fallback / rollback'])
card(1139,721,323,135,'Persistence',['SPM: seed + JSON files','TSSA: SQLite WAL + AES-GCM','Revision · idempotency · audit'])
card(1139,874,323,142,'Dịch vụ tùy chọn',['BGE-M3 qua HTTP adapter','Đã test provider mô phỏng','Chưa xác nhận model thật'],color='#fff3dd')

text(38,1081,'Bản đồ cấu trúc source. Kiểm thử không thay thế usability đại diện, phê duyệt tổ chức hoặc backup/retention review.',size=20,color='#60708b')
svg.append('</svg>')
canvas.save(out/'module-map.png')
(out/'module-map.svg').write_text('\n'.join(svg),encoding='utf-8')
print('Rendered module-map.png and module-map.svg')
