*** Settings ***
Documentation     ทดสอบหน้าปฏิทินการจอง — ชื่อเดือน, เดือนก่อน/ถัดไป, dropdown เดือน, เลือกวัน,
...               รายละเอียดรายการของวัน, popover ตอน hover, ปุ่ม "จองใหม่" และ "ดูทั้งหมด"
...               suite setup สร้างรายการยืมของวันนี้ผ่าน API เพื่อให้ agenda มีข้อมูลแน่นอน
...               (teardown ปฏิเสธรายการนั้นเพื่อคืนจำนวนให้ครุภัณฑ์ — รันซ้ำได้)
Resource          ../../resources/common.resource
Resource          ../../resources/api_client.resource
Resource          ../../resources/pages/calendar_page.resource
Suite Setup       Prepare Calendar Suite
Suite Teardown    Cleanup Calendar Suite
Test Setup        Open Calendar
Test Tags         calendar    ui


*** Keywords ***
Prepare Calendar Suite
    Create Api Session
    ${tx}=    Create Borrow Transaction For Today    note=Robot E2E calendar
    Set Suite Variable    ${TX}    ${tx}
    Open App    /login
    Start Fresh Session

Cleanup Calendar Suite
    Run Keyword And Ignore Error    Reject Transaction    ${TX}[id]
    Close App

Open Calendar
    Go To    ${BASE_URL}/calendar
    Calendar Page Should Be Loaded

Agenda Should Contain Created Transaction
    ${card}=    Set Variable    ${CAL_AGENDA_ITEM} >> text=${TX}[code] >> xpath=ancestor::article[1]
    Wait For Elements State    ${card}    visible    timeout=10s
    Get Text    ${card}    contains    ${TX}[equipmentName]
    Get Text    ${card}    contains    ${TX}[userName]
    Get Text    ${card}    contains    ยืม · ${TX}[code]
    RETURN    ${card}

Card Status Should Match Api
    [Arguments]    ${card}
    [Documentation]    ถ้าไม่ตรง (สถานะเพิ่งถูกเปลี่ยนจากที่อื่น) ให้ reload หน้าแล้วลองใหม่
    ${live}=    Get Transaction    ${TX}[id]
    ${label}    ${short}=    Status Labels For    ${live}[status]
    ${ok}=    Run Keyword And Return Status    Get Text    ${card} >> css=.cal-status    ==    ${label}
    IF    not ${ok}
        Open Calendar
        ${today}=    Today Day Number
        Select Day    ${today}
    END
    Get Text    ${card} >> css=.cal-status    ==    ${label}
    Get Text    ${card} >> css=.cal-chip    ==    ${short}


*** Test Cases ***
Page Header And Current Month Are Shown
    [Tags]    smoke
    Get Text    ${CALENDAR} >> css=.page-head__title    ==    ปฏิทินการจอง
    ${title}=    Thai Month Title
    Month Title Should Be    ${title}
    Get Element Count    ${CAL_PANEL} >> css=.cal-weekdays span    ==    7
    ${today}=    Today Day Number
    Day Should Be Selected    ${today}
    ${cell}=    Day Cell    ${today}
    Get Attribute    ${cell}    class    contains    is-today
    Agenda Date Should Be    ${today}    ${title}
    Capture Page    96-calendar-month

Previous And Next Month Change The Title
    [Documentation]    เปลี่ยนเดือน → ชื่อเดือนเปลี่ยน และเลือกวันที่ 1 ของเดือนนั้นอัตโนมัติ
    ...                กลับมาเดือนปัจจุบัน → เลือกวันนี้
    ${current}=    Thai Month Title
    ${prev}=    Thai Month Title    -1
    ${next}=    Thai Month Title    1
    Click    ${CAL_PREV}
    Month Title Should Be    ${prev}
    Day Should Be Selected    1
    Agenda Date Should Be    1    ${prev}
    Click    ${CAL_NEXT}
    Month Title Should Be    ${current}
    ${today}=    Today Day Number
    Day Should Be Selected    ${today}
    Click    ${CAL_NEXT}
    Month Title Should Be    ${next}
    Agenda Date Should Be    1    ${next}

Month Dropdown Jumps To Chosen Month
    ${target}=    Thai Month Title    -3
    Click    ${CAL_MONTH}
    Wait For Elements State    ${CAL_MONTH_MENU_ITEM} >> nth=0    visible    timeout=10s
    Get Element Count    ${CAL_MONTH_MENU_ITEM}    ==    12
    Click    ${CAL_MONTH_MENU_ITEM} >> text="${target}"
    Month Title Should Be    ${target}
    Agenda Date Should Be    1    ${target}

Clicking A Day Selects It And Updates Agenda
    [Documentation]    เลือกวันอื่น → วันนั้นถูกไฮไลต์ หัว agenda เปลี่ยนเป็นวันที่นั้น และจำนวนตรงกับการ์ด
    ${title}=    Thai Month Title
    ${today}=    Today Day Number
    ${other}=    Evaluate    1 if ${today} != 1 else 2
    Select Day    ${other}
    Day Should Be Selected    ${other}
    ${cell}=    Day Cell    ${today}
    Get Attribute    ${cell}    aria-pressed    ==    false
    Agenda Date Should Be    ${other}    ${title}
    Agenda Count Should Match Cards
    Select Day    ${today}
    Agenda Date Should Be    ${today}    ${title}

Today Shows Created Borrow In Agenda
    [Documentation]    รายการยืมที่สร้างใน setup ต้องขึ้นในรายละเอียดของวันนี้ พร้อมชื่อครุภัณฑ์ ผู้ยืม เวลา และสถานะ
    [Tags]    critical
    ${today}=    Today Day Number
    ${cell}=    Day Cell    ${today}
    Wait For Elements State    ${cell} >> ${CAL_BADGE}    visible    timeout=10s
    Select Day    ${today}
    ${card}=    Agenda Should Contain Created Transaction
    Get Text    ${card} >> css=.cal-card__title span    matches    ^\\d{2}:\\d{2} - .*\\d{2}:\\d{2}$
    # รายการใหม่เป็น pending ("รอยืนยัน"/"รอ") แต่ suite อื่นที่รันพร้อมกันอาจเปลี่ยนสถานะไปแล้ว
    # จึงเทียบกับสถานะจริงจาก API ณ ตอนนี้
    Wait Until Keyword Succeeds    3x    1s    Card Status Should Match Api    ${card}
    ${count}=    Agenda Count Should Match Cards
    Should Be True    ${count} >= 1
    Capture Page    97-calendar-agenda

Hovering A Busy Day Shows Popover
    [Documentation]    hover วันที่มีรายการ → popover "รายการจองวันนี้" + จำนวนรายการ
    ${today}=    Today Day Number
    ${cell}=    Day Cell    ${today}
    Hover    ${cell}
    Wait For Elements State    css=.cal-tip .cal-tip__head    visible    timeout=10s
    Get Text    css=.cal-tip .cal-tip__head    contains    รายการจองวันนี้
    Get Text    css=.cal-tip .cal-tip__head .cal-count    matches    ^\\d+ รายการ$
    Capture Page    98-calendar-popover

Empty Day Shows No Items Message
    [Documentation]    เดือนในอนาคตยังไม่มีการยืม → agenda ว่าง "ไม่มีรายการในวันนี้" และ 0 รายการ
    ${future}=    Thai Month Title    12
    FOR    ${i}    IN RANGE    12
        Click    ${CAL_NEXT}
    END
    Month Title Should Be    ${future}
    Wait For Elements State    ${CAL_PANEL} >> css=.ant-spin-spinning    detached    timeout=20s
    Select Day    15
    Wait For Elements State    ${CAL_AGENDA_EMPTY}    visible    timeout=10s
    Get Text    ${CAL_AGENDA_EMPTY}    contains    ไม่มีรายการในวันนี้
    Get Text    ${CAL_AGENDA_COUNT}    ==    0 รายการ
    Get Element Count    ${CAL_BADGE}    ==    0

New Booking Button Opens Borrow Form
    Click    ${CAL_NEW}
    Url Should Be    /borrow/new
    Wait Until Keyword Succeeds    5x    1s    Page Title Should Be    Borrow

View All Button Opens Borrow List
    Click    ${CAL_ALL}
    Url Should Be    /borrow
    Transactions Page Should Be Loaded
