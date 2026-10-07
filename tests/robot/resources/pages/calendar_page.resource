*** Settings ***
Documentation     Page Object ของหน้าปฏิทินการจอง (/calendar)
Library           Browser
Library           String
Variables         ../variables.py


*** Variables ***
${CALENDAR}              css=[data-testid="calendar-page"]
${CAL_PANEL}             css=[data-testid="calendar-panel"]
${CAL_MONTH}             css=[data-testid="calendar-month"]
${CAL_PREV}              css=[data-testid="calendar-prev"]
${CAL_NEXT}              css=[data-testid="calendar-next"]
${CAL_NEW}               css=[data-testid="calendar-new"]
${CAL_ALL}               css=[data-testid="calendar-all"]
${CAL_AGENDA}            css=[data-testid="calendar-agenda"]
${CAL_AGENDA_DATE}       css=[data-testid="calendar-agenda"] .cal-agenda__head p
${CAL_AGENDA_COUNT}      css=[data-testid="calendar-agenda-count"]
${CAL_AGENDA_ITEM}       css=[data-testid="calendar-agenda-item"]
${CAL_AGENDA_EMPTY}      css=[data-testid="calendar-agenda"] .ant-empty
${CAL_BADGE}             css=[data-testid="calendar-badge"]
${CAL_MONTH_MENU_ITEM}   css=.ant-dropdown:not(.ant-dropdown-hidden) .ant-dropdown-menu-item
@{THAI_MONTHS}           มกราคม    กุมภาพันธ์    มีนาคม    เมษายน    พฤษภาคม    มิถุนายน
...                      กรกฎาคม    สิงหาคม    กันยายน    ตุลาคม    พฤศจิกายน    ธันวาคม


*** Keywords ***
Calendar Page Should Be Loaded
    Wait For Elements State    ${CALENDAR}    visible    timeout=20s
    Wait For Elements State    ${CAL_MONTH}    visible    timeout=10s
    # Spin ครอบตารางระหว่างโหลด — รอจนหาย
    Wait For Elements State    ${CAL_PANEL} >> css=.ant-spin-spinning    detached    timeout=20s

Thai Month Title
    [Arguments]    ${offset}=0
    [Documentation]    ชื่อเดือนไทย + พ.ศ. ของเดือนปัจจุบัน ± offset เช่น "กันยายน 2569"
    ${now}=    Get Time    year month    NOW
    ${index}=    Evaluate    int($now[0]) * 12 + int($now[1]) - 1 + int($offset)
    ${year}=    Evaluate    ${index} // 12 + 543
    ${month}=    Evaluate    ${index} % 12
    RETURN    ${THAI_MONTHS}[${month}] ${year}

Month Title Should Be
    [Arguments]    ${expected}
    Wait For Condition    Text    ${CAL_MONTH}    ==    ${expected}    timeout=10s

Today Day Number
    ${day}=    Get Time    day    NOW
    ${day}=    Convert To Integer    ${day}
    RETURN    ${day}

Day Cell
    [Arguments]    ${day}
    RETURN    css=[data-testid="calendar-day-${day}"]

Select Day
    [Arguments]    ${day}
    ${cell}=    Day Cell    ${day}
    Click    ${cell}
    Get Attribute    ${cell}    aria-pressed    ==    true

Day Should Be Selected
    [Arguments]    ${day}
    ${cell}=    Day Cell    ${day}
    Get Attribute    ${cell}    aria-pressed    ==    true
    Get Attribute    ${cell}    class    contains    is-selected

Agenda Date Should Be
    [Arguments]    ${day}    ${month_title}
    Wait For Condition    Text    ${CAL_AGENDA_DATE}    ==    ${day} ${month_title}    timeout=10s

Agenda Count Should Match Cards
    [Documentation]    ตัวเลข "N รายการ" ที่หัวต้องเท่ากับจำนวนการ์ด
    ${text}=    Get Text    ${CAL_AGENDA_COUNT}
    ${n}=    Fetch From Left    ${text}    ${SPACE}
    ${cards}=    Get Element Count    ${CAL_AGENDA_ITEM}
    Should Be Equal As Integers    ${n}    ${cards}
    RETURN    ${cards}

Choose Month From Dropdown
    [Arguments]    ${month_title}
    Click    ${CAL_MONTH}
    Wait For Elements State    ${CAL_MONTH_MENU_ITEM} >> nth=0    visible    timeout=10s
    Click    ${CAL_MONTH_MENU_ITEM} >> text="${month_title}"

Status Labels For
    [Arguments]    ${status}
    [Documentation]    ข้อความสถานะ (หัวการ์ด, pill) ตาม STATUS_META ใน calendar-page.tsx
    ${labels}=    Create Dictionary
    ...    pending=รอยืนยัน|รอ
    ...    approved=ยืนยันแล้ว|ยืนยันแล้ว
    ...    in_progress=กำลังยืม|กำลังยืม
    ...    complete=เสร็จสิ้น|เสร็จสิ้น
    ...    rejected=ปฏิเสธ|ปฏิเสธ
    @{pair}=    Split String    ${labels}[${status}]    |
    RETURN    @{pair}
