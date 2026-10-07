*** Settings ***
Documentation     ทดสอบโครงหน้าหลังล็อกอิน (sidebar + header) ครบทุก action
...               — ลิงก์เมนูทุกตัว + ไฮไลต์, ย่อ/ขยาย, กระดิ่ง, เมนูผู้ใช้, ปุ่มโปรไฟล์ท้าย sidebar,
...               ปุ่ม EN|TH, ออกจากระบบ, route ที่ไม่มีอยู่
Resource          ../../resources/common.resource
Suite Setup       Run Keywords    Open App    /login    AND    Start Fresh Session
Suite Teardown    Close App
Test Setup        Go To Dashboard
Test Tags         shell    navigation    ui


*** Keywords ***
Go To Dashboard
    [Documentation]    ทุก test เริ่มจาก Dashboard ที่ล็อกอินอยู่ (ถ้า session หลุดให้ล็อกอินใหม่)
    Go To    ${BASE_URL}/
    ${on_login}=    Run Keyword And Return Status
    ...    Wait For Elements State    ${LOGIN_SUBMIT}    visible    timeout=3s
    IF    ${on_login}    Login Through UI
    Dashboard Should Be Loaded
    Shell Should Be Ready

Click Menu And Verify
    [Arguments]    ${menu}    ${title}    ${path}
    Navigate To    ${menu}    ${title}
    Url Should Be    ${path}
    Only This Nav Should Be Highlighted    ${menu}


*** Test Cases ***
Every Sidebar Link Navigates And Highlights Itself
    [Documentation]    คลิกทุกเมนู → URL ถูกต้อง, ชื่อหน้าเปลี่ยน และมีเมนูถูกไฮไลต์แค่ตัวเดียว
    [Tags]    smoke
    Only This Nav Should Be Highlighted    ${NAV_DASHBOARD}
    Click Menu And Verify    ${NAV_ADD_PRODUCT}      Add Products       /equipment/new
    Click Menu And Verify    ${NAV_BORROW}           Borrow             /borrow
    Click Menu And Verify    ${NAV_RETURN}           Return             /return
    Click Menu And Verify    ${NAV_CALENDAR}         Calendar           /calendar
    Click Menu And Verify    ${NAV_REPORTS}          Product Reports    /reports
    Click Menu And Verify    ${NAV_NOTIFICATIONS}    Notifications      /notifications
    Click Menu And Verify    ${NAV_SETTINGS}         Settings           /settings
    Capture Page    80-shell-settings-highlighted
    Click Menu And Verify    ${NAV_DASHBOARD}        Dashboard          /

Sub Routes Highlight Their Parent Menu
    [Documentation]    /borrow/new และ /return/new ต้องไฮไลต์เมนูแม่ (Borrow / Return) ไม่ใช่ Dashboard
    Go To    ${BASE_URL}/borrow/new
    Wait Until Keyword Succeeds    5x    1s    Page Title Should Be    Borrow
    Only This Nav Should Be Highlighted    ${NAV_BORROW}
    Go To    ${BASE_URL}/return/new
    Wait Until Keyword Succeeds    5x    1s    Page Title Should Be    Return
    Only This Nav Should Be Highlighted    ${NAV_RETURN}

Sidebar Collapse Hides Labels And Expand Restores Them
    [Documentation]    ย่อ → เหลือไอคอน (ชื่อแบรนด์/ชื่อผู้ใช้ท้ายเมนูหาย กว้าง 76px) · ขยาย → กลับมาครบ
    ${wide}=    Get BoundingBox    ${SIDEBAR}    width
    Should Be True    ${wide} > 200
    Collapse Sidebar
    Wait For Elements State    ${SIDEBAR_USER}    detached    timeout=10s
    Get Attribute    ${SIDEBAR_TOGGLE}    aria-label    ==    ขยายเมนู
    Wait Until Keyword Succeeds    10x    300ms    Sidebar Width Should Be Below    100
    Capture Page    81-shell-collapsed
    Expand Sidebar
    Wait For Elements State    ${SIDEBAR_USER}    visible    timeout=10s
    Get Attribute    ${SIDEBAR_TOGGLE}    aria-label    ==    ย่อเมนู
    Wait Until Keyword Succeeds    10x    300ms    Sidebar Width Should Be Above    200

Header Bell Opens Notifications
    Click    ${HEADER_BELL}
    Wait For Elements State    css=[data-testid="notifications-page"]    visible    timeout=15s
    Url Should Be    /notifications
    Page Title Should Be    Notifications
    Nav Should Be Highlighted    ${NAV_NOTIFICATIONS}

User Menu Profile Opens Settings
    [Documentation]    เมนูผู้ใช้มี "โปรไฟล์ของฉัน" และ "ออกจากระบบ" — กดโปรไฟล์ → /settings
    Open User Menu
    Get Text    ${MENU_PROFILE}    ==    โปรไฟล์ของฉัน
    Get Text    ${LOGOUT_BUTTON}    ==    ออกจากระบบ
    Capture Page    82-shell-user-menu
    Click    ${MENU_PROFILE}
    Wait For Elements State    css=[data-testid="settings-page"]    visible    timeout=15s
    Url Should Be    /settings
    Nav Should Be Highlighted    ${NAV_SETTINGS}

Sidebar Footer Opens Settings
    [Documentation]    ปุ่มผู้ใช้ท้าย sidebar ("Welcome back") → /settings
    Get Text    ${SIDEBAR_FOOT}    contains    Welcome back
    Get Text    ${SIDEBAR_USER}    ==    ${USER_NAME}
    Click    ${SIDEBAR_FOOT}
    Wait For Elements State    css=[data-testid="settings-page"]    visible    timeout=15s
    Url Should Be    /settings

Header Shows User Name And Role
    Get Text    ${HEADER_USER}    ==    ${USER_NAME}
    Get Text    ${HEADER_USER_MENU} >> css=small    ==    Admin

Language Toggle EN And TH Is Present
    [Documentation]    ปุ่ม EN|TH แสดงอยู่ (EN เป็นค่าปัจจุบัน) — ยังไม่มีการแปลภาษา กดแล้วหน้าต้องไม่พัง
    Wait For Elements State    ${HEADER_LANG}    visible
    Get Text    ${HEADER_LANG} >> css=button >> nth=0    ==    EN
    Get Text    ${HEADER_LANG} >> css=button >> nth=1    ==    TH
    Get Attribute    ${HEADER_LANG} >> css=button >> nth=0    class    contains    is-active
    Click    ${HEADER_LANG} >> css=button >> nth=1
    Dashboard Should Be Loaded
    Url Should Be    /

Unknown Route Shows Not Found Page
    [Documentation]    path ที่ไม่มีใน router → หน้า 404 ของแอป (อยู่ใน shell) และปุ่มพากลับ Dashboard ได้
    Go To    ${BASE_URL}/this-page-does-not-exist
    Wait For Elements State    css=[data-testid="not-found-page"]    visible    timeout=10s
    Get Text    css=[data-testid="not-found-page"]    contains    404
    Wait For Elements State    ${SIDEBAR}    visible
    Capture Page    83-shell-unknown-route
    Click    css=[data-testid="not-found-home"]
    Dashboard Should Be Loaded

Logout From Header Clears Session
    [Documentation]    ออกจากระบบ → กลับ /login, sessionStorage ถูกล้าง และเข้า route ที่ต้องล็อกอินไม่ได้อีก
    Logout
    Login Page Should Be Shown
    ${token}=    Session Storage Get Item    access_token
    Should Be Equal    ${token}    ${None}
    Go To    ${BASE_URL}/reports
    Login Page Should Be Shown
    Capture Page    84-shell-after-logout
    [Teardown]    Login Through UI


*** Keywords ***
Sidebar Width Should Be Below
    [Arguments]    ${max}
    ${w}=    Get BoundingBox    ${SIDEBAR}    width
    Should Be True    ${w} < ${max}    sidebar กว้าง ${w}

Sidebar Width Should Be Above
    [Arguments]    ${min}
    ${w}=    Get BoundingBox    ${SIDEBAR}    width
    Should Be True    ${w} > ${min}    sidebar กว้าง ${w}
