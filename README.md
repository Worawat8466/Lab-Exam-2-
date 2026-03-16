# 📱 AI Receipt & Expense Tracker

แอปพลิเคชันบันทึกรายรับ-รายจ่ายอัจฉริยะ สำหรับโปรเจกต์สอบปฏิบัติการครั้งที่ 2 (Lab Exam 2) วิชาการพัฒนาแอปพลิเคชันระดับองค์กร (Enterprise Flutter Application Development) 🚀

แอปพลิเคชันนี้ออกแบบมาให้รองรับการทำงานแบบ Offline-First, ช่วยกรอกข้อมูลอัตโนมัติจากสลิปโอนเงินผ่านการทำงานร่วมกันระหว่าง On-device ML Kit และ Gemini AI รวมถึงผ่านการทดสอบครอบคลุมทั้ง Unit, Widget และ Integration Test เพื่อสถาปัตยกรรมที่แข็งแกร่งและได้มาตรฐาน

## 1) 🌟 ภาพรวมโปรเจกต์ (Project Overview)
ฟีเจอร์หลักในการใช้งาน:
- **เพิ่มรายรับ/รายจ่ายด้วยตัวเอง:** รองรับการกรอกฟอร์มพร้อมระบบตรวจสอบความถูกต้อง (Form Validation) อย่างครบถ้วน
- **สแกนสลิปอัจฉริยะ:** เลือกหรือถ่ายรูปสลิปโอนเงิน แล้วให้ AI ช่วยดึงข้อมูลสำคัญ (วันที่, จำนวนเงิน, หมวดหมู่) ลงฟอร์มให้อัตโนมัติ ยกระดับ UX ให้ผู้ใช้
- **ดึงข้อมูลแม่นยำด้วย ML Kit:** สามารถตรวจจับ QR Code บนสลิปภาพด้วย Google ML Kit Barcode Scanning เพื่อวิเคราะห์ฝั่ง On-device ได้รวดเร็วก่อนส่งภาพให้ AI
- **รองรับการใช้งานออฟไลน์ (Offline-First):** บันทึกและแสดงผลประวัติได้ทันทีผ่านฐานข้อมูล Isar บนเครื่อง แม้ไม่มีการเชื่อมต่ออินเทอร์เน็ต
- **Dashboard ควบคุมรายจ่าย:** แสดงผลรูปแบบกราฟวงกลม สรุปงบประมาณ และมี AI ผู้ช่วยการเงินส่วนตัว (Financial Assistant) ให้คำแนะนำอย่างเป็นธรรมชาติ

## 2) 🛠️ เทคโนโลยีและเครื่องมือที่ใช้ (Technical Stack)
- **Architecture:** Clean Architecture + Repository Pattern
- **State Management:** Riverpod
- **Dependency Injection:** get_it
- **Domain Error Handling:** dartz (ใช้ `Either<Failure, Success>`)
- **Local Database (ฐานข้อมูลหลัก):** Isar (สำหรับการจัดเก็บ Offline First)
- **Local Storage (รอง/แคช):** Hive, SharedPreferences
- **Networking:** Dio + Interceptors
- **Data Mapping & Serialization:** freezed + json_serializable
- **Routing:** auto_route
- **On-device ML:** `google_mlkit_barcode_scanning`
- **Cloud AI:** Gemini API (รองรับ Vision สกัดข้อความจากภาพ และ Text วิเคราะห์พฤติกรรมการเงิน)

## 3) 🏗️ สถาปัตยกรรม (Architecture)
แบ่งโครงสร้างของโปรเจกต์ออกเป็นเลเยอร์ (Layers) ให้สอดคล้องกับหลักการ Clean Architecture โดยอิงตามฟีเจอร์ (Feature-based):
- **Domain:** อัดแน่นไปด้วย Business Logic หลัก ได้แก่ Entities, Repositories (Contracts) และ UseCases
- **Data:** ส่วนเชื่อมต่อข้อมูลและ API ได้แก่ DataSources (Local และ Remote), Repository Implementations และ DTO/Models เเมปปิ้งข้อมูล
- **Presentation:** ส่วนการแสดงผล ได้แก่ Pages, Widgets และ Riverpod Providers/Notifiers สำหรับจัดการสถานะหน้าจอแบบ Reactive

📌 *ไฟล์ตั้งค่า Dependency Injection หลักอยู่ที่:* `lib/app/di/service_locator.dart`

## 4) 🎯 การรองรับข้อกำหนดของข้อสอบ (Rubric Requirement Mapping)

### 4.1 Architecture and State Management
- **Clean Architecture + Repository Pattern:** ประยุกต์ใช้งานในทุก `features/*` 
- **Dependency Injection:** ผูกพึ่งพา (Dependencies) ในสเกลใหญ่ด้วย `get_it`
- **State Management:** อัปเดตและเก็บสถานะหน้าจอใหม่อย่างเป็นระบบตัวด้วย Riverpod 

### 4.2 Offline-First and Local Storage
- **Main Local DB:** เรียกใช้ Isar เก็บประวัติทางการเงิน (Expense) ทำให้ค้นหาข้อมูลได้แม่ไม่มีเน็ต 
- **Key-Value Settings:** แคชการตั้งค่า (เช่น ธีม, ภาษา) ผ่าน SharedPreferences
- **Caching:** ผสมผสานระบบ Hive เพื่อทำ Cache ของ Gemini ช่วยลดการเกิด Request API โดยไม่จำเป็น

### 4.3 Networking and API
- เชื่อมต่อและดึงข้อมูลด้วย Dio
- ฝัง API Key ของแอปอย่างปลอดภัยด้วย Custom Interceptors (`lib/core/network/api_key_interceptor.dart`) และ BYOK (Bring Your Own Key) ในหน้าตั้งค่า
- จัดเป็น Object พร็อพเพอร์ตี้ที่แน่นอนด้วย `freezed` และ `json_serializable`

### 4.4 AI and ML Integration
- **On-device ML Kit:** ตรวจหาและถอดรหัส QR ออฟไลน์ก่อน (เร็วกว่า ใช้ทรัพยากรน้อยกว่า)
- **Cloud LLM:** ใช้งาน Gemini API สกัดข้อมูลตัวอักษรรวมถึงโลโก้/รูปแบบบิล เพื่อแปลงให้เป็น JSON Form โครงสร้าง
- **Service หลักที่ทำงานประสานกัน:** `lib/features/receipt_scan/data/services/e_slip_scanner_service.dart`

### 4.5 UI, Routing, Forms, Animations
- **Routing:** ควบคุมการเปลี่ยนหน้า ป้อนพารามิเตอร์ ผ่าน `auto_route`
- **Forms:** ดักจับการสแปมและกรอกค่าต่างๆ ผ่าน `GlobalKey<FormState>` ในหน้าเพิ่มรายการการโอน
- **Animations:** เสริมความ Enterprise ด้วยการรันภาพลื่นไหลอย่าง `Hero` Transitions จากหน้ารายการไปยังหน้ารายละเอียด รวมถึงใช้ Implicit Animations สร้างการสลับกราฟิกสวยงาม

### 4.6 Testing (สคริปต์ทดสอบครบวงจร)
- ทำ **Unit tests** ทดสอบ Logic ฟังก์ชันหลัก
- ทำ **Widget tests** ทดสอบองค์ประกอบ UI และ Riverpod interactions
- ทำ **Integration tests** ทดสอบแบบ E2E จบทุก Flows ใน App ทะลุแบบอัตโนมัติ

## 5) ⚙️ การตั้งค่าสภาพแวดล้อม (Environment Setup)
เพื่อความปลอดภัย ก่อนทดสอบโปรแกรมโปรดสร้างไฟล์ `.env` ที่ root folder ของโปรเจกต์ (ไม่ต้องแนบลงระบบ Git):

```dotenv
GEMINI_API_KEY=your_real_api_key_here
GEMINI_MODEL=gemini-2.5-flash
```

## 6) 🚀 คำสั่งสำหรับรันโปรเจกต์ (Run Commands)

**ติดตั้ง Library เเละ Dependencies:**
```bash
flutter pub get
```

**สั่งสร้าง Code Generator (เมื่อมีการเเก้ตัว Data Model เเละ Route):**
```bash
dart run build_runner build --delete-conflicting-outputs
```

**รันแอปพลิเคชันหน้าปกติ:**
```bash
flutter run
```

**รันชุดทดสอบความถูกต้อง:**
```bash
flutter test
flutter test integration_test/app_e2e_test.dart
flutter test integration_test/scan_receipt_device_test.dart
```

## 7) ✅ เช็คลิสต์ตรวจสอบก่อนการให้คะแนน (Final Submission Checklist)

### Source Code และความปลอดภัย
- [x] อัปโหลดโปรเจกต์ขึ้นเก็บในเซิร์ฟเวอร์เรียบร้อย
- [x] ตรวจสอบ ไม่มีการหลุดหลงไหลของตัวแปร API Key ใน Git / `.env`
- [x] README ถูกแก้ไขล่าสุดให้พร้อมและทันสมัย

### การทดสอบระบบ (Functional Demo)
- [x] สาธิตภาพรวมและการเปิดตัวแอปพลิเคชัน
- [x] สาธิตหน้าพิมพ์ข้อมูล (Manual Add) รวมถึงระบบป้องกันกรอกผิด (Form Validation)
- [x] สาธิตดึงภาพสลิปให้ระบบ AI ถอดค่ากรอกฟอร์มอัตโนมัติ (ML + LLM OCR)
- [x] สาธิตการรองรับ Offline-First (ปิดเน็ต ก็ยังต้องดึงข้อมูล Transaction ที่บันทึกไปแล้วมาแสดงได้)
- [x] สาธิตขั้นตอนจัดการหมวดหมู่และแท็ก (Manage Categories/Tags)
- [x] สาธิตภาพรวมและ AI ผู้ช่วยให้คำแนะนำที่มีการเปลี่ยนไปตามเงื่อนไข (Dashboard Summary updates)

### สถาปัตยกรรมระดับ Enterprise (Mandatory Technical Evidence)
- [x] ตรวจสอบกลไก Dependency Injection (`get_it`)
- [x] ตรวจสอบวิธีการนำไปใช้ State Management (`Riverpod`)
- [x] สาธิตฐานข้อมูลทาง Local Data (`Isar` / `Hive` / `SharedPreferences`)
- [x] สาธิตการเชื่อมโยงระบบ Networking (`Dio` & `Interceptor`)
- [x] สาธิตระบบ `ML Kit` บนอุปกรณ์
- [x] สาธิตการประมวลผล Language Model ใน Cloud (`Gemini`)
- [x] สาธิตการจัดการ Routing Structure (`auto_route`)
- [x] สาธิตการใช้เทคนิค UI ป้องกันผู้ใช้งานแบบ Animations (`Hero` & `Implicit transitions`)

### ตัววัดผลฝั่ง Testing Evidence
- [x] รันชุด Unit Tests เป็นสีเขียวทั้งหมด
- [x] รันชุด Widget Tests ผ่านหมด
- [x] รันชุด Integration Tests เสร็จสิ้นสมบูรณ์เตรียมตัวพร้อมเสมอ
    
---
พัฒนาสำหรับการศึกษาและส่งงานทดสอบภาคปฏิบัติครั้งที่ 2 รายวิชา **Enterprise Flutter Application Development** ✨
