*** Settings ***
Documentation     Keyword กลาง — เปิด/ปิด browser, ล้าง session, ล็อกอิน
Library           Browser
Library           RequestsLibrary
Variables         variables.py
Resource          pages/login_page.resource
Resource          pages/shell.resource
Resource          pages/dashboard_page.resource
Resource          pages/equipment_page.resource
Resource          pages/transactions_page.resource


*** Keywords ***
Open App
    [Arguments]    ${path}=/
    [Documentation]    เปิด browser ใหม่ไปที่ path ที่ระบุ
    New Browser    chromium    headless=${HEADLESS}    slowMo=${SLOW_MO}
    New Context    viewport={'width': 1440, 'height': 900}    locale=th-TH
    New Page    ${BASE_URL}${path}

Close App
    Close Browser    ALL

Clear Session
    [Documentation]    ล้าง session ของ test ก่อนหน้า — ไม่งั้น test ถัดไปจะยังล็อกอินค้างอยู่
    ...                ต้องอยู่บน origin เดียวกันก่อนถึงจะเข้าถึง sessionStorage ได้
    Go To    ${BASE_URL}/login
    Session Storage Clear
    Delete All Cookies

Login Through UI
    [Arguments]    ${email}=${USER}    ${password}=${PASSWORD}
    [Documentation]    ล็อกอินผ่านหน้าจอจริง แล้วรอจน dashboard พร้อม
    Open Login Page
    Login With    ${email}    ${password}
    Dashboard Should Be Loaded

Start Fresh Session
    [Documentation]    ใช้เป็น Test Setup ของ suite ที่ต้องล็อกอินใหม่ทุกครั้ง
    Clear Session
    Login Through UI

Capture Page
    [Arguments]    ${name}
    [Documentation]    ถ่ายภาพทั้งหน้า เก็บที่ results/browser/screenshot/<name>.png และแนบใน log.html
    Take Screenshot    filename=${name}    fullPage=True
