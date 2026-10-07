*** Settings ***
Documentation     Page Object ของหน้าการแจ้งเตือน (/notifications)
Library           Browser
Library           String
Variables         ../variables.py


*** Variables ***
${NOTIFICATIONS}        css=[data-testid="notifications-page"]
${NT_ITEM}              css=[data-testid="notification-item"]
${NT_UNREAD_ITEM}       css=[data-testid="notification-item"].is-unread
${NT_MARK_ALL}          css=[data-testid="mark-all-read"]
${NT_BADGE}             css=[data-testid="notifications-page"] .section-card__badge
${NT_VIEW}              css=[data-testid="notifications-page"] .nt-view
${NT_VIEW_SELECTED}     css=[data-testid="notifications-page"] .nt-view .ant-segmented-item-selected
${NT_EMPTY}             css=[data-testid="notifications-page"] .nt-empty


*** Keywords ***
Notifications Page Should Be Loaded
    Wait For Elements State    ${NOTIFICATIONS}    visible    timeout=20s
    Wait For Elements State    ${NOTIFICATIONS} >> css=.ant-spin-spinning    detached    timeout=20s

Switch Notification View
    [Arguments]    ${label}
    [Documentation]    Segmented "ทั้งหมด" / "ยังไม่อ่าน"
    Click    ${NT_VIEW} >> css=.ant-segmented-item >> text="${label}"
    Get Text    ${NT_VIEW_SELECTED}    ==    ${label}

Unread Badge Count
    [Documentation]    อ่านตัวเลขจากป้าย "N ยังไม่อ่าน" — ไม่มีป้าย = 0
    ${count}=    Get Element Count    ${NT_BADGE}
    IF    ${count} == 0    RETURN    ${0}
    ${text}=    Get Text    ${NT_BADGE}
    ${n}=    Fetch From Left    ${text}    ${SPACE}
    ${n}=    Convert To Integer    ${n}
    RETURN    ${n}

Unread Badge Should Be At Least
    [Arguments]    ${minimum}
    ${n}=    Unread Badge Count
    Should Be True    ${n} >= ${minimum}    ป้ายยังไม่อ่านต้อง >= ${minimum} แต่ได้ ${n}
