*** Settings ***
Documentation     Page Object ของหน้าเข้าสู่ระบบ — selector รวมไว้ที่นี่ที่เดียว
Library           Browser
Variables         ../variables.py


*** Variables ***
${LOGIN_URL}          ${BASE_URL}/login
${LOGIN_TITLE}        css=[data-testid="login-title"]
${LOGIN_EMAIL}        css=[data-testid="login-email"]
${LOGIN_PASSWORD}     css=[data-testid="login-password"]
${LOGIN_SUBMIT}       css=[data-testid="login-submit"]
${LOGIN_ERROR}        css=[data-testid="login-error"]
${LOGIN_GOOGLE}       css=[data-testid="login-google"]
${LOGIN_FORGOT}       css=[data-testid="login-forgot"]
${LOGIN_REGISTER}     css=[data-testid="login-register"]
${FIELD_ERROR}        css=.ant-form-item-explain-error


*** Keywords ***
Open Login Page
    [Documentation]    เปิดหน้า /login และรอจนฟอร์มพร้อมใช้งาน
    Go To    ${LOGIN_URL}
    Reload
    Wait For Elements State    ${LOGIN_SUBMIT}    visible    timeout=15s

Fill Login Form
    [Arguments]    ${email}    ${password}
    Fill Text    ${LOGIN_EMAIL}    ${email}
    Fill Text    ${LOGIN_PASSWORD}    ${password}

Submit Login Form
    Click    ${LOGIN_SUBMIT}

Login With
    [Arguments]    ${email}=${USER}    ${password}=${PASSWORD}
    [Documentation]    กรอกฟอร์ม + กดเข้าสู่ระบบ (ไม่ตรวจผลลัพธ์)
    Fill Login Form    ${email}    ${password}
    Submit Login Form

Login Error Should Be Shown
    [Arguments]    ${expected}=อีเมลหรือรหัสผ่านไม่ถูกต้อง
    Wait For Elements State    ${LOGIN_ERROR}    visible    timeout=15s
    Get Text    ${LOGIN_ERROR}    contains    ${expected}

# ── ส่วนเพิ่มเติม ──
*** Keywords ***
Login Page Should Be Shown
    [Documentation]    อยู่หน้า /login และฟอร์มพร้อมใช้
    ...                รอได้ถึง 25 วินาที เพราะ logout รอ POST /auth/logout ให้จบก่อน (axios timeout 15s)
    Wait For Elements State    ${LOGIN_SUBMIT}    visible    timeout=25s
    Wait For Condition    Url    ==    ${LOGIN_URL}    timeout=10s
