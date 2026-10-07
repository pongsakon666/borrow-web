*** Settings ***
Documentation     Page Object ของโครงหน้าหลังล็อกอิน — sidebar, header, เมนู
Library           Browser
Variables         ../variables.py


*** Variables ***
${SIDEBAR}            css=[data-testid="app-sidebar"]
${SIDEBAR_TOGGLE}     css=[data-testid="sidebar-toggle"]
${SIDEBAR_USER}       css=[data-testid="sidebar-user"]
${PAGE_TITLE}         css=[data-testid="page-title"]
${HEADER_USER_MENU}   css=[data-testid="header-user-menu"]
${HEADER_USER}        css=[data-testid="header-user"]
${HEADER_BELL}        css=[data-testid="header-bell"]
${LOGOUT_BUTTON}      css=[data-testid="logout-button"]

# เมนูด้านซ้าย — testid มาจาก path (ดู app-sidebar.tsx)
${NAV_DASHBOARD}      css=[data-testid="nav-dashboard"]
${NAV_ADD_PRODUCT}    css=[data-testid="nav-equipment-new"]
${NAV_BORROW}         css=[data-testid="nav-borrow"]
${NAV_RETURN}         css=[data-testid="nav-return"]
${NAV_CALENDAR}       css=[data-testid="nav-calendar"]
${NAV_REPORTS}        css=[data-testid="nav-reports"]
${NAV_NOTIFICATIONS}  css=[data-testid="nav-notifications"]
${NAV_SETTINGS}       css=[data-testid="nav-settings"]


*** Keywords ***
Shell Should Be Ready
    [Documentation]    โครงหน้าหลังล็อกอินโหลดครบ
    Wait For Elements State    ${SIDEBAR}    visible    timeout=15s
    Wait For Elements State    ${HEADER_USER}    visible    timeout=15s

Page Title Should Be
    [Arguments]    ${expected}
    Get Text    ${PAGE_TITLE}    ==    ${expected}

Navigate To
    [Arguments]    ${menu}    ${expected_title}
    [Documentation]    คลิกเมนูซ้าย แล้วรอจน header เปลี่ยนชื่อหน้า
    Click    ${menu}
    Wait Until Keyword Succeeds    5x    1s    Page Title Should Be    ${expected_title}

Open User Menu
    Click    ${HEADER_USER_MENU}
    Wait For Elements State    ${LOGOUT_BUTTON}    visible    timeout=10s

Logout
    [Documentation]    ปุ่มออกจากระบบอยู่ใน dropdown ต้องเปิดเมนูก่อน
    Open User Menu
    Click    ${LOGOUT_BUTTON}

# ── ส่วนเพิ่มเติมสำหรับ suites/ui/shell.robot ──
*** Variables ***
${SIDEBAR_FOOT}       css=button.app-sider__foot
${SIDEBAR_WORDMARK}   css=.app-sider__wordmark
${HEADER_LANG}        css=[data-testid="header-lang"]
${HEADER_BADGE}       css=.app-header__right .ant-badge-count
${MENU_PROFILE}       css=[data-testid="menu-profile"]
${SELECTED_CLASS}     ant-menu-item-selected


*** Keywords ***
Nav Should Be Highlighted
    [Arguments]    ${menu}
    [Documentation]    เมนูที่ตรงกับหน้าปัจจุบันต้องมี class ant-menu-item-selected ที่ <li> ของมัน
    Get Attribute    ${menu} >> xpath=ancestor::li[1]    class    contains    ${SELECTED_CLASS}

Nav Should Not Be Highlighted
    [Arguments]    ${menu}
    Get Attribute    ${menu} >> xpath=ancestor::li[1]    class    not contains    ${SELECTED_CLASS}

Only This Nav Should Be Highlighted
    [Arguments]    ${menu}
    [Documentation]    ต้องมีเมนูถูกเลือกแค่ 1 รายการเท่านั้น (เช่น /equipment/new ห้ามไฮไลต์ Dashboard ด้วย)
    Nav Should Be Highlighted    ${menu}
    Get Element Count    ${SIDEBAR} >> css=li.${SELECTED_CLASS}    ==    1

Url Should Be
    [Arguments]    ${path}
    [Documentation]    รอจน URL เป็น path ที่ระบุ (SPA เปลี่ยน URL แบบ async)
    Wait For Condition    Url    ==    ${BASE_URL}${path}    timeout=10s

Open Profile From User Menu
    [Documentation]    เมนูผู้ใช้ → โปรไฟล์ของฉัน → ไปหน้า /settings
    Open User Menu
    Click    ${MENU_PROFILE}

Collapse Sidebar
    Click    ${SIDEBAR_TOGGLE}
    Wait For Elements State    ${SIDEBAR_WORDMARK}    detached    timeout=10s

Expand Sidebar
    Click    ${SIDEBAR_TOGGLE}
    Wait For Elements State    ${SIDEBAR_WORDMARK}    visible    timeout=10s

Header Unread Badge Should Be
    [Arguments]    ${expected}
    [Documentation]    antd Badge ซ่อนตัวเลขเมื่อเป็น 0 — 0 จึงหมายถึง "ไม่มี badge"
    IF    ${expected} == 0
        Wait For Elements State    ${HEADER_BADGE}    detached    timeout=10s
    ELSE
        Wait For Elements State    ${HEADER_BADGE}    visible    timeout=10s
        # title เป็น string เสมอ — แปลง expected (อาจเป็น int) ให้เป็น string ก่อนเทียบ
        Get Attribute    ${HEADER_BADGE}    title    ==    ${{ str($expected) }}
    END
