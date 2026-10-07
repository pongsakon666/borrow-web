*** Settings ***
Documentation     ทดสอบทุก action บนหน้า /borrow — การ์ดสถิติ ค้นหา ตัวกรอง เพิ่มรายการ สลับมุมมอง
...               จ่าย/รับคืนอุปกรณ์ผ่าน modal ยืนยัน ดูรายละเอียด และแบ่งหน้า
...               ข้อมูลที่ใช้ทดสอบสร้างผ่าน API (ครุภัณฑ์รหัสไม่ซ้ำ + รายการจอง) เพื่อให้รันซ้ำได้
Resource          ../../resources/common.resource
Suite Setup       Prepare Borrow Suite
Suite Teardown    Cleanup Borrow Suite
Test Setup        Open Borrow Page
Test Tags         transactions    borrow    ui


*** Variables ***
${EQUIPMENT}      ${None}
@{CREATED}        @{EMPTY}


*** Keywords ***
Prepare Borrow Suite
    [Documentation]    เปิด browser + ล็อกอิน และสร้างครุภัณฑ์เฉพาะของ suite นี้ผ่าน API
    Open App    /login
    Start Fresh Session
    ${auth}=    Api Login
    Set Suite Variable    ${AUTH}    ${auth}
    ${stamp}=    Unique Stamp
    ${equipment}=    Api Create Equipment    ${AUTH}    E2E-BA-${stamp}    ครุภัณฑ์ทดสอบหน้ายืม ${stamp}    ${50}
    Set Suite Variable    ${EQUIPMENT}    ${equipment}

Cleanup Borrow Suite
    [Documentation]    ปิดรายการที่ค้างให้เป็น complete แล้วลบครุภัณฑ์ทดสอบ
    FOR    ${id}    IN    @{CREATED}
        Run Keyword And Ignore Error    Api Set Transaction Status    ${AUTH}    ${id}    complete
    END
    IF    $EQUIPMENT    Run Keyword And Ignore Error    Api Delete Equipment    ${AUTH}    ${EQUIPMENT}[id]
    Close App

Open Borrow Page
    Go To    ${BASE_URL}/borrow
    Wait Until Page Visible    ${TX_PAGE}
    Transactions Page Should Be Loaded
    Hide Dev Overlays

Create Booking
    [Arguments]    ${channel}=Walk-in
    [Documentation]    สร้างรายการจอง (pending) ผ่าน API พร้อม note ชื่อผู้จอง แล้วคืน JSON ของรายการ
    ${stamp}=    Unique Stamp
    ${booker}=    Set Variable    ผู้จองทดสอบ ${stamp}
    ${note}=    Borrow Note    ${booker}    ${channel}
    ${tx}=    Api Create Transaction    ${AUTH}    borrow    ${EQUIPMENT}[id]    ${note}
    Append To List    ${CREATED}    ${tx}[id]
    Set To Dictionary    ${tx}    booker=${booker}
    RETURN    ${tx}

Confirm Modal Should Be Closed
    Wait For Elements State    ${TX_ACTION_CONFIRM}    detached    timeout=10s

Stat Should Be Greater Than
    [Arguments]    ${card}    ${before}
    ${now}=    Read Stat Count    ${card}
    Should Be True    ${now} > ${before}    ${card}: ${now} ต้องมากกว่า ${before}

First Row Should Not Be
    [Arguments]    ${previous}
    ${current}=    Get Text    ${TX_ROWS} >> nth=0
    Should Not Be Equal    ${current}    ${previous}


*** Test Cases ***
Header And Stat Cards Render
    [Documentation]    หัวหน้า "รายการยืมวันนี้" + การ์ดสถิติ 4 ใบ แสดงตัวเลข "N รายการ"
    [Tags]    smoke
    Get Text    ${BORROW_HEADER}    contains    รายการยืมวันนี้
    Get Text    ${BORROW_HEADER}    contains    จัดการและตรวจสอบรายการจ่ายเครื่องมือ
    Stat Card Should Show Count    ${BORROW_STAT_TOTAL}    รายการวันนี้ทั้งหมด
    Stat Card Should Show Count    ${BORROW_STAT_BOOKING}    จองล่วงหน้า
    Stat Card Should Show Count    ${BORROW_STAT_WALKIN}    Walk-in
    Stat Card Should Show Count    ${BORROW_STAT_ISSUED}    อุปกรณ์ถูกจ่ายแล้ว
    Get Text    ${BORROW_SECTION_BOOKING}    contains    รายการจองล่วงหน้า
    Get Text    ${BORROW_SECTION_WALKIN}    contains    รายการผู้ขอยืม Walk-in
    Capture Page    60-borrow-stats

Stat Cards Count Today's New Booking
    [Documentation]    สร้างรายการ Walk-in วันนี้ → การ์ดรวมและ Walk-in ต้องไม่ลดลงและนับรายการใหม่
    ${total_before}=    Read Stat Count    ${BORROW_STAT_TOTAL}
    ${walkin_before}=    Read Stat Count    ${BORROW_STAT_WALKIN}
    Create Booking    Walk-in
    Reload Transactions Page
    Wait Until Keyword Succeeds    10x    1s    Stat Should Be Greater Than    ${BORROW_STAT_TOTAL}    ${total_before}
    Wait Until Keyword Succeeds    10x    1s    Stat Should Be Greater Than    ${BORROW_STAT_WALKIN}    ${walkin_before}

Search By Booking Code Shows Only That Booking
    [Documentation]    ค้นหาด้วยรหัสรายการ → เหลือแถวเดียว · ล้างช่องค้นหา (ปุ่ม x) → กลับมาแสดงทั้งหมด
    ${tx}=    Create Booking
    Reload Transactions Page
    ${row}=    Search Until Row Appears    ${tx}[code]
    Wait Until Keyword Succeeds    10x    1s    Get Element Count    ${TX_ROWS}    ==    1
    Get Text    ${row}    contains    ${tx}[booker]
    Get Text    ${row}    contains    ${EQUIPMENT}[name]
    Capture Page    61-borrow-search-code
    Click    css=[data-testid="tx-search"] .ant-input-clear-icon
    Wait Until Keyword Succeeds    10x    1s    Get Element Count    ${TX_ROWS}    >    1

Search With No Match Shows Empty State
    [Documentation]    ค้นหาคำที่ไม่มีในระบบ → ทั้งสองตารางแสดง "ไม่มีรายการ" และไม่มี pagination
    Search Transactions    ไม่มีรายการนี้แน่นอน-${EQUIPMENT}[code]
    Wait Until Keyword Succeeds    10x    1s    Get Element Count    ${TX_ROWS}    ==    0
    Get Text    ${BORROW_SECTION_BOOKING}    contains    ไม่มีรายการ
    Get Text    ${BORROW_SECTION_WALKIN}    contains    ไม่มีรายการ
    Get Element Count    ${BORROW_PAGINATION}    ==    0

Advanced Filter Shows Only Selected Status
    [Documentation]    ตัวกรองขั้นสูง → "กำลังยืม" ทุกแถวต้องเป็นสถานะนั้น · เลือก "ทุกสถานะ" กลับเป็นป้ายเดิม
    Get Text    ${TX_STATUS}    contains    ตัวกรองขั้นสูง
    Choose Dropdown Option    ${TX_STATUS}    กำลังยืม
    Get Text    ${TX_STATUS}    contains    กำลังยืม
    Wait Until Keyword Succeeds    10x    1s    Every Visible Row Should Have Element    [data-testid="status-in_progress"]
    Capture Page    62-borrow-filter-in-progress
    Choose Dropdown Option    ${TX_STATUS}    รอรับของ (รออนุมัติ)
    Wait Until Keyword Succeeds    10x    1s    Every Visible Row Should Have Element    [data-testid="status-pending"]
    Choose Dropdown Option    ${TX_STATUS}    ทุกสถานะ
    Get Text    ${TX_STATUS}    contains    ตัวกรองขั้นสูง
    Transactions Page Should Be Loaded

Add Button Opens Borrow Form
    [Documentation]    "+ เพิ่มรายการ" → ไปหน้า /borrow/new
    Get Text    ${BORROW_ADD}    contains    เพิ่มรายการ
    Click    ${BORROW_ADD}
    Url Should End With    /borrow/new
    Wait For Elements State    ${BF_PAGE}    visible    timeout=15s

Table And List View Toggle
    [Documentation]    ปุ่มสลับมุมมองของแต่ละตาราง: ตาราง ↔ รายการ (ul.borrow-list) โดยไม่กระทบอีกตาราง
    ${tx}=    Create Booking    Walk-in
    Reload Transactions Page
    Search Until Row Appears    ${tx}[code]
    ${walkin_list_btn}=    Set Variable    ${BORROW_SECTION_WALKIN} >> ${VIEW_LIST_BTN}
    ${walkin_table_btn}=    Set Variable    ${BORROW_SECTION_WALKIN} >> ${VIEW_TABLE_BTN}
    Get Attribute    ${walkin_table_btn}    class    contains    is-active
    Click    ${walkin_list_btn}
    Get Attribute    ${walkin_list_btn}    class    contains    is-active
    Wait For Elements State    ${BORROW_SECTION_WALKIN} >> css=ul.borrow-list    visible    timeout=10s
    Get Element Count    ${BORROW_SECTION_WALKIN} >> css=.ant-table    ==    0
    Get Text    ${BORROW_SECTION_WALKIN} >> css=ul.borrow-list    contains    ${tx}[booker]
    # การจัดการในมุมมองรายการยังใช้ได้
    Get Element Count    ${BORROW_SECTION_WALKIN} >> css=ul.borrow-list [data-testid="tx-issue"]    ==    1
    # ตารางจองล่วงหน้ายังเป็นมุมมองตาราง
    Wait For Elements State    ${BORROW_SECTION_BOOKING} >> css=.ant-table    visible
    Capture Page    63-borrow-list-view
    Click    ${walkin_table_btn}
    Wait For Elements State    ${BORROW_SECTION_WALKIN} >> css=.ant-table    visible    timeout=10s
    Get Element Count    ${BORROW_SECTION_WALKIN} >> css=ul.borrow-list    ==    0
    Click    ${BORROW_SECTION_BOOKING} >> ${VIEW_LIST_BTN}
    Get Attribute    ${BORROW_SECTION_BOOKING} >> ${VIEW_LIST_BTN}    class    contains    is-active
    Get Element Count    ${BORROW_SECTION_BOOKING} >> css=.ant-table    ==    0
    Click    ${BORROW_SECTION_BOOKING} >> ${VIEW_TABLE_BTN}
    Wait For Elements State    ${BORROW_SECTION_BOOKING} >> css=.ant-table    visible

Issue And Return Equipment Through Confirm Modals
    [Documentation]    จ่ายอุปกรณ์ → modal ยืนยัน → สถานะ "กำลังยืม" · คืนอุปกรณ์ → modal → "จ่ายแล้ว"
    [Tags]    smoke
    ${tx}=    Create Booking    จองผ่านระบบ
    Reload Transactions Page
    ${row}=    Search Until Row Appears    ${tx}[code]
    Get Text    ${row} >> css=[data-testid="status-pending"]    contains    รอรับของ
    Get Text    ${BORROW_SECTION_BOOKING}    contains    ${tx}[code]
    Click    ${row} >> ${TX_ISSUE}
    Wait For Elements State    ${TX_ACTION_CONFIRM}    visible    timeout=10s
    Get Text    ${TX_ACTION_CONFIRM}    contains    ยืนยันการจ่ายอุปกรณ์
    Get Text    ${TX_ACTION_CONFIRM}    contains    ${EQUIPMENT}[name] × 1
    Capture Page    64-borrow-issue-confirm
    Click    ${TX_ACTION_OK}
    Confirm Modal Should Be Closed
    Message Should Appear    อัปเดตสถานะแล้ว
    Wait For Elements State    ${row} >> css=[data-testid="status-in_progress"]    visible    timeout=15s
    Get Text    ${row} >> css=[data-testid="status-in_progress"]    contains    กำลังยืม
    Api Transaction Status Should Be    ${AUTH}    ${tx}[id]    in_progress
    Capture Page    65-borrow-issued
    Click    ${row} >> ${TX_RETURN}
    Wait For Elements State    ${TX_ACTION_CONFIRM}    visible    timeout=10s
    Get Text    ${TX_ACTION_CONFIRM}    contains    ยืนยันการรับคืนอุปกรณ์
    Click    ${TX_ACTION_OK}
    Confirm Modal Should Be Closed
    Wait For Elements State    ${row} >> css=[data-testid="status-complete"]    visible    timeout=15s
    Get Text    ${row} >> css=[data-testid="status-complete"]    contains    จ่ายแล้ว
    Api Transaction Status Should Be    ${AUTH}    ${tx}[id]    complete
    # รายการที่ปิดแล้วเหลือปุ่ม "ดูรายละเอียด"
    Get Text    ${row} >> ${TX_DETAIL}    ==    ดูรายละเอียด

Cancelling Confirm Modal Changes Nothing
    [Documentation]    กด "ยกเลิก" ใน modal จ่ายอุปกรณ์ / ปิดด้วย X → สถานะเดิม ปุ่มเดิม และ API ไม่เปลี่ยน
    ${tx}=    Create Booking
    Reload Transactions Page
    ${row}=    Search Until Row Appears    ${tx}[code]
    Click    ${row} >> ${TX_ISSUE}
    Wait For Elements State    ${TX_ACTION_CONFIRM}    visible    timeout=10s
    Click    ${TX_ACTION_CANCEL}
    Confirm Modal Should Be Closed
    Click    ${row} >> ${TX_ISSUE}
    Wait For Elements State    ${TX_ACTION_CONFIRM}    visible    timeout=10s
    Close Open Modal
    Confirm Modal Should Be Closed
    Wait For Elements State    ${row} >> css=[data-testid="status-pending"]    visible
    Get Text    ${row} >> ${TX_ISSUE}    ==    จ่ายอุปกรณ์
    Api Transaction Status Should Be    ${AUTH}    ${tx}[id]    pending
    Capture Page    66-borrow-cancel-unchanged

Detail Modal Opens And Closes
    [Documentation]    "ดูรายละเอียด" → modal แสดงรหัส ผู้จอง เบอร์ หน่วยงาน อุปกรณ์ ช่องทาง · ปิดด้วย X
    ${tx}=    Create Booking    Walk-in
    Api Set Transaction Status    ${AUTH}    ${tx}[id]    complete
    Reload Transactions Page
    ${row}=    Search Until Row Appears    ${tx}[code]
    Click    ${row} >> ${TX_DETAIL}
    Wait For Elements State    ${TX_DETAIL_MODAL}    visible    timeout=10s
    Get Text    css=.borrow-detail .ant-modal-title    ==    รายละเอียดรายการ
    Get Text    ${TX_DETAIL_MODAL}    contains    ${tx}[code]
    Get Text    ${TX_DETAIL_MODAL}    contains    ${tx}[booker]
    Get Text    ${TX_DETAIL_MODAL}    contains    081-000-0000
    Get Text    ${TX_DETAIL_MODAL}    contains    ฝ่ายทดสอบ E2E
    Get Text    ${TX_DETAIL_MODAL}    contains    ${EQUIPMENT}[name] (${EQUIPMENT}[code]) × 1
    Get Text    ${TX_DETAIL_MODAL}    contains    Walk-in
    Get Text    ${TX_DETAIL_MODAL}    contains    จ่ายแล้ว
    Capture Page    67-borrow-detail-modal
    Close Open Modal
    Wait For Elements State    ${TX_DETAIL_MODAL}    detached    timeout=10s

Pagination Next Previous And Total
    [Documentation]    แบ่งหน้า: แสดงยอดรวม · ปุ่มถัดไป → หน้า 2 (ข้อมูลเปลี่ยน) · ก่อนหน้า → กลับหน้า 1
    Wait For Elements State    ${BORROW_PAGINATION}    visible    timeout=10s
    Get Text    ${BORROW_PAGINATION}    matches    ทั้งหมด [\\d,]+ รายการ
    Get Attribute    ${BORROW_PAGINATION} .ant-pagination-item-1    class    contains    ant-pagination-item-active
    ${first}=    Get Text    ${TX_ROWS} >> nth=0
    Click    ${BORROW_PAGINATION} .ant-pagination-next
    Wait Until Keyword Succeeds    10x    1s
    ...    Get Attribute    ${BORROW_PAGINATION} .ant-pagination-item-2    class    contains    ant-pagination-item-active
    Wait Until Keyword Succeeds    10x    1s    First Row Should Not Be    ${first}
    Capture Page    68-borrow-page2
    Click    ${BORROW_PAGINATION} .ant-pagination-prev
    Wait Until Keyword Succeeds    10x    1s
    ...    Get Attribute    ${BORROW_PAGINATION} .ant-pagination-item-1    class    contains    ant-pagination-item-active

Filter Resets Pagination To First Page
    [Documentation]    อยู่หน้า 2 แล้วเปลี่ยนตัวกรอง → กลับไปหน้า 1
    Click    ${BORROW_PAGINATION} .ant-pagination-item-2
    Wait Until Keyword Succeeds    10x    1s
    ...    Get Attribute    ${BORROW_PAGINATION} .ant-pagination-item-2    class    contains    ant-pagination-item-active
    Choose Dropdown Option    ${TX_STATUS}    จ่ายแล้ว
    Wait Until Keyword Succeeds    10x    1s
    ...    Get Attribute    ${BORROW_PAGINATION} .ant-pagination-item-1    class    contains    ant-pagination-item-active
    Wait Until Keyword Succeeds    10x    1s    Every Visible Row Should Have Element    [data-testid="status-complete"]

