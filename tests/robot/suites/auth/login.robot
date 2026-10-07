*** Settings ***
Documentation     ทดสอบหน้าเข้าสู่ระบบ — ต้องมี FE (:5173) และ BE (:3001) รันอยู่
...               ทุก test case เก็บ screenshot ไว้ดูใน results/log.html
Resource          ../../resources/common.resource
Suite Setup       Open App    /login
Suite Teardown    Close App
Test Setup        Start From Clean Login Page
Test Tags         auth    ui


*** Keywords ***
Start From Clean Login Page
    Clear Session
    Open Login Page


*** Test Cases ***
Login Page Is Rendered
    [Documentation]    หน้า login แสดงครบตามดีไซน์
    [Tags]    smoke
    Get Text    ${LOGIN_TITLE}    ==    เข้าสู่ระบบ
    Get Text    css=.auth-card__header    contains    ระบบยืม-คืนครุภัณฑ์
    Wait For Elements State    ${LOGIN_EMAIL}    visible
    Wait For Elements State    ${LOGIN_PASSWORD}    visible
    Wait For Elements State    ${LOGIN_GOOGLE}    visible
    Wait For Elements State    ${LOGIN_FORGOT}    visible
    Wait For Elements State    ${LOGIN_REGISTER}    visible
    Get Text    css=.auth-card__foot    ==    Riverpark
    Capture Page    01-login-page

Login Succeeds With Valid Credentials
    [Documentation]    ล็อกอินสำเร็จ → เข้าหน้า Dashboard และแสดงชื่อผู้ใช้
    [Tags]    smoke
    Fill Login Form    ${USER}    ${PASSWORD}
    Capture Page    02-login-filled
    Submit Login Form
    Dashboard Should Be Loaded
    Shell Should Be Ready
    Get Text    ${HEADER_USER}    ==    ${USER_NAME}
    Get Text    ${SIDEBAR_USER}    ==    ${USER_NAME}
    Get Url    ==    ${BASE_URL}/
    Capture Page    03-dashboard-after-login

Login Fails With Wrong Password
    [Documentation]    รหัสผ่านผิด → ขึ้น alert และยังอยู่หน้า login
    Login With    ${USER}    WrongPassword123
    Login Error Should Be Shown    อีเมลหรือรหัสผ่านไม่ถูกต้อง
    Get Url    ==    ${LOGIN_URL}
    Capture Page    04-login-wrong-password

Login Fails With Unknown Email
    [Documentation]    อีเมลที่ไม่มีในระบบ → ข้อความเหมือนรหัสผ่านผิด (กัน user enumeration)
    Login With    nobody@example.com    ${PASSWORD}
    Login Error Should Be Shown    อีเมลหรือรหัสผ่านไม่ถูกต้อง
    Capture Page    05-login-unknown-email

Empty Form Shows Field Validation
    [Documentation]    กดเข้าสู่ระบบโดยไม่กรอก → ขึ้น error ใต้ช่องกรอก ไม่ยิง API
    Submit Login Form
    Wait For Elements State    ${FIELD_ERROR} >> nth=0    visible    timeout=10s
    ${errors}=    Get Elements    ${FIELD_ERROR}
    Length Should Be    ${errors}    2
    Get Text    ${FIELD_ERROR} >> nth=0    ==    กรุณากรอกอีเมล
    Get Text    ${FIELD_ERROR} >> nth=1    ==    กรุณากรอกรหัสผ่าน
    Get Url    ==    ${LOGIN_URL}
    Capture Page    06-login-empty-validation

Invalid Email Format Is Rejected
    [Documentation]    อีเมลผิดรูปแบบ → validate ฝั่ง FE ก่อนส่ง
    Fill Login Form    not-an-email    ${PASSWORD}
    Submit Login Form
    Wait For Elements State    ${FIELD_ERROR} >> nth=0    visible    timeout=10s
    Get Text    ${FIELD_ERROR} >> nth=0    ==    รูปแบบอีเมลไม่ถูกต้อง
    Get Url    ==    ${LOGIN_URL}
    Capture Page    07-login-invalid-email

Logout Returns To Login Page
    [Documentation]    ออกจากระบบผ่านเมนูผู้ใช้ → กลับหน้า login
    Login With
    Dashboard Should Be Loaded
    Logout
    Wait For Elements State    ${LOGIN_SUBMIT}    visible    timeout=15s
    Get Url    ==    ${LOGIN_URL}
    Capture Page    08-after-logout

Login Page Works On Mobile Viewport
    [Documentation]    จอเล็ก (390x844) — ภาพประกอบถูกซ่อน เหลือเฉพาะฟอร์ม และยังล็อกอินได้
    [Tags]    responsive
    Set Viewport Size    390    844
    Open Login Page
    Wait For Elements State    ${LOGIN_SUBMIT}    visible    timeout=15s
    Get Element States    css=.auth-visual    contains    hidden
    Capture Page    09-login-mobile
    Login With
    Dashboard Should Be Loaded
    Capture Page    10-dashboard-mobile
    [Teardown]    Set Viewport Size    1440    900
