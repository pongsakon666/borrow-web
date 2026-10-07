*** Settings ***
Documentation     ทดสอบการนำทางด้วยเมนูด้านซ้าย — ทุกหน้าเปิดได้และ header เปลี่ยนชื่อถูกต้อง
Resource          ../../resources/common.resource
Suite Setup       Run Keywords    Open App    /login    AND    Start Fresh Session
Suite Teardown    Close App
Test Tags         navigation    ui


*** Test Cases ***
Sidebar Shows All Menu Items
    Shell Should Be Ready
    FOR    ${menu}    IN
    ...    ${NAV_DASHBOARD}    ${NAV_ADD_PRODUCT}    ${NAV_BORROW}    ${NAV_RETURN}
    ...    ${NAV_CALENDAR}    ${NAV_REPORTS}    ${NAV_NOTIFICATIONS}    ${NAV_SETTINGS}
        Wait For Elements State    ${menu}    visible    timeout=10s
    END

Navigate Through Every Page
    [Documentation]    คลิกทีละเมนู แล้วตรวจว่าเนื้อหาของหน้านั้นโหลดจริง
    [Tags]    smoke
    Navigate To    ${NAV_ADD_PRODUCT}    Add Products
    Wait For Elements State    ${WIZARD}    visible    timeout=15s

    Navigate To    ${NAV_BORROW}    Borrow
    Transactions Page Should Be Loaded

    Navigate To    ${NAV_RETURN}    Return
    Transactions Page Should Be Loaded

    Navigate To    ${NAV_CALENDAR}    Calendar
    Wait For Elements State    css=[data-testid="calendar-page"]    visible    timeout=15s

    Navigate To    ${NAV_REPORTS}    Product Reports
    Wait For Elements State    ${EQ_LIST}    visible    timeout=15s

    Navigate To    ${NAV_NOTIFICATIONS}    Notifications
    Wait For Elements State    css=[data-testid="notifications-page"]    visible    timeout=15s

    Navigate To    ${NAV_SETTINGS}    Settings
    Wait For Elements State    css=[data-testid="settings-page"]    visible    timeout=15s
    Get Text    css=[data-testid="settings-user-email"]    ==    ${USER}

    Navigate To    ${NAV_DASHBOARD}    Dashboard
    Dashboard Should Be Loaded
    Capture Page    24-navigation-back-to-dashboard

Sidebar Can Be Collapsed And Expanded
    [Documentation]    ปุ่มย่อ/ขยายเมนู — ย่อแล้วชื่อแบรนด์หาย ขยายแล้วกลับมา
    Wait For Elements State    css=.app-sider__wordmark    visible    timeout=10s
    Click    ${SIDEBAR_TOGGLE}
    Wait For Elements State    css=.app-sider__wordmark    detached    timeout=10s
    Capture Page    25-sidebar-collapsed
    Click    ${SIDEBAR_TOGGLE}
    Wait For Elements State    css=.app-sider__wordmark    visible    timeout=10s

Notification Bell Opens Notifications Page
    Click    ${HEADER_BELL}
    Wait For Elements State    css=[data-testid="notifications-page"]    visible    timeout=15s
    Page Title Should Be    Notifications
    [Teardown]    Navigate To    ${NAV_DASHBOARD}    Dashboard
