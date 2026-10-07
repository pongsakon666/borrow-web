*** Settings ***
Documentation     ทดสอบหน้าการแจ้งเตือน — รายการ, ตัวกรอง ทั้งหมด/ยังไม่อ่าน, ปุ่ม "อ่านทั้งหมด"
...               และ badge บนกระดิ่งที่ header
...               BE ไม่มี API สร้างการแจ้งเตือน (มีแค่จาก seed) จึงเพิ่มแถวลง SQLite ของ API ตรง ๆ
...               ทุก test (NotificationSeed.py) แล้วลบทิ้งตอนจบ — รันซ้ำได้เสมอ
Resource          ../../resources/common.resource
Resource          ../../resources/pages/notifications_page.resource
Library           ../../resources/libs/NotificationSeed.py
Suite Setup       Run Keywords    Open App    /login    AND    Start Fresh Session
Suite Teardown    Close App
Test Setup        Seed And Open Notifications
Test Teardown     Remove Seeded Notification
Test Tags         notifications    ui


*** Keywords ***
Remove Seeded Notification
    IF    $SEEDED_ID    Delete Notification    ${SEEDED_ID}

Seed And Open Notifications
    Set Test Variable    ${SEEDED_ID}    ${None}
    ${stamp}=    Get Time    epoch
    ${message}=    Set Variable    แจ้งเตือนจากการทดสอบ ${stamp}
    ${id}=    Seed Unread Notification    ${message}
    Set Test Variable    ${SEEDED_ID}    ${id}
    Set Test Variable    ${SEEDED_MESSAGE}    ${message}
    # reload ทั้งหน้าเพื่อล้าง cache ของ React Query (header badge มี staleTime 60s)
    Go To    ${BASE_URL}/notifications
    Reload
    Notifications Page Should Be Loaded
    Wait For Elements State    ${NT_ITEM} >> text=${SEEDED_MESSAGE}    visible    timeout=15s

Seeded Item
    RETURN    ${NT_ITEM} >> text=${SEEDED_MESSAGE} >> xpath=ancestor::li[1]


*** Test Cases ***
List Shows Notification Items
    [Tags]    smoke
    Get Text    ${NOTIFICATIONS} >> css=.page-head__title    ==    การแจ้งเตือน
    ${count}=    Get Element Count    ${NT_ITEM}
    Should Be True    ${count} >= 1
    ${item}=    Seeded Item
    Get Text    ${item}    contains    Robot E2E
    Get Attribute    ${item}    class    contains    is-unread
    Wait For Elements State    ${item} >> css=.nt-item__dot    visible
    # ทุกแถวต้องมีข้อความและชื่อผู้ทำรายการ · เวลา
    FOR    ${i}    IN RANGE    ${count}
        ${text}=    Get Text    ${NT_ITEM} >> nth=${i} >> css=.nt-item__text p
        Should Not Be Empty    ${text}
        Get Text    ${NT_ITEM} >> nth=${i} >> css=.nt-item__text small    contains    ·
    END
    Capture Page    99-notifications-list

Unread Filter Shows Only Unread Items
    [Documentation]    ตัวกรอง "ยังไม่อ่าน" → เหลือเฉพาะแถว is-unread และจำนวนตรงกับป้าย "N ยังไม่อ่าน"
    Get Text    ${NT_VIEW_SELECTED}    ==    ทั้งหมด
    ${all}=    Get Element Count    ${NT_ITEM}
    ${badge}=    Unread Badge Count
    Should Be True    ${badge} >= 1
    Switch Notification View    ยังไม่อ่าน
    Wait For Condition    Element Count    ${NT_ITEM}    ==    ${badge}    timeout=10s
    Get Element Count    ${NT_UNREAD_ITEM}    ==    ${badge}
    Wait For Elements State    ${NT_ITEM} >> text=${SEEDED_MESSAGE}    visible
    Switch Notification View    ทั้งหมด
    Wait For Condition    Element Count    ${NT_ITEM}    ==    ${all}    timeout=10s

Header Bell Badge Matches Unread Count
    ${badge}=    Unread Badge Count
    Header Unread Badge Should Be    ${badge}

Mark All Read Clears Unread State
    [Documentation]    "อ่านทั้งหมด" → toast, ป้ายยังไม่อ่านหาย, ปุ่มถูก disable, badge กระดิ่งหาย,
    ...                ตัวกรอง "ยังไม่อ่าน" ว่างเปล่า
    [Tags]    critical
    Unread Badge Should Be At Least    1
    Get Element States    ${NT_MARK_ALL}    contains    enabled
    Click    ${NT_MARK_ALL}
    Wait For Elements State    css=.ant-message-notice >> text=ทำเครื่องหมายว่าอ่านแล้วทั้งหมด    visible    timeout=10s
    Wait For Elements State    ${NT_BADGE}    detached    timeout=10s
    Wait For Elements State    ${NT_MARK_ALL}    disabled    timeout=10s
    Wait For Condition    Element Count    ${NT_UNREAD_ITEM}    ==    0    timeout=10s
    ${item}=    Seeded Item
    Get Attribute    ${item}    class    not contains    is-unread
    Header Unread Badge Should Be    0
    Switch Notification View    ยังไม่อ่าน
    Wait For Elements State    ${NT_EMPTY}    visible    timeout=10s
    Get Text    ${NT_EMPTY}    contains    ไม่มีการแจ้งเตือนที่ยังไม่อ่าน
    Capture Page    99-notifications-all-read

Dashboard Rail Shows Latest Notification
    [Documentation]    การแจ้งเตือนล่าสุดต้องขึ้นในกล่อง "การแจ้งเตือน" ของ Dashboard ด้วย
    Navigate To    ${NAV_DASHBOARD}    Dashboard
    Dashboard Should Be Loaded
    Wait For Elements State    ${RAIL_NOTIFICATIONS} >> css=.rail-row >> text=${SEEDED_MESSAGE}    visible    timeout=15s

Bell Opens This Page
    Navigate To    ${NAV_DASHBOARD}    Dashboard
    Click    ${HEADER_BELL}
    Notifications Page Should Be Loaded
    Url Should Be    /notifications
