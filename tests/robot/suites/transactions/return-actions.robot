*** Settings ***
Documentation     ทดสอบทุก action บนหน้า /return — การ์ดสถิติ ค้นหา ตัวกรองสถานะ ปุ่ม "คืนของ"
...               ยืนยันรับคืนผ่าน modal (ยืนยัน/ยกเลิก) ดูรายละเอียด และแบ่งหน้า
...               รายการคืนที่ใช้ทดสอบสร้างผ่าน API ด้วยครุภัณฑ์และชื่อผู้คืนที่ไม่ซ้ำ
Resource          ../../resources/common.resource
Suite Setup       Prepare Return Suite
Suite Teardown    Cleanup Return Suite
Test Setup        Open Return Page
Test Tags         transactions    return    ui


*** Variables ***
${EQUIPMENT}      ${None}
@{CREATED}        @{EMPTY}


*** Keywords ***
Prepare Return Suite
    Open App    /login
    Start Fresh Session
    ${auth}=    Api Login
    Set Suite Variable    ${AUTH}    ${auth}
    ${stamp}=    Unique Stamp
    ${equipment}=    Api Create Equipment    ${AUTH}    E2E-RA-${stamp}    ครุภัณฑ์ทดสอบหน้าคืน ${stamp}    ${50}
    Set Suite Variable    ${EQUIPMENT}    ${equipment}

Cleanup Return Suite
    FOR    ${id}    IN    @{CREATED}
        Run Keyword And Ignore Error    Api Set Transaction Status    ${AUTH}    ${id}    complete
    END
    IF    $EQUIPMENT    Run Keyword And Ignore Error    Api Delete Equipment    ${AUTH}    ${EQUIPMENT}[id]
    Close App

Open Return Page
    Go To    ${BASE_URL}/return
    Wait Until Page Visible    ${TX_PAGE}
    Transactions Page Should Be Loaded
    Hide Dev Overlays

Create Return
    [Arguments]    ${status}=pending    ${condition}=ใช้งานปกติ
    [Documentation]    ยืม 1 ชิ้นแล้วสร้างรายการคืนผ่าน API (note แบบเดียวกับหน้า intake) และตั้งสถานะตามต้องการ
    ${stamp}=    Unique Stamp
    ${returner}=    Set Variable    ผู้คืนทดสอบ ${stamp}
    ${borrow}=    Api Create Transaction    ${AUTH}    borrow    ${EQUIPMENT}[id]
    Append To List    ${CREATED}    ${borrow}[id]
    ${note}=    Set Variable    สภาพ: ${condition} · เหตุผล: ครบกำหนดยืม · ผู้คืน: ${returner} · อ้างอิง: ${borrow}[code]
    ${tx}=    Api Create Transaction    ${AUTH}    return    ${EQUIPMENT}[id]    ${note}
    Append To List    ${CREATED}    ${tx}[id]
    IF    '${status}' != 'complete'    Api Set Transaction Status    ${AUTH}    ${tx}[id]    ${status}
    Set To Dictionary    ${tx}    returner=${returner}    borrow_code=${borrow}[code]
    RETURN    ${tx}

Find Return Row
    [Arguments]    ${tx}
    [Documentation]    ค้นหาด้วยรหัสรายการ แล้วคืน locator ของแถวของผู้คืนคนนี้
    Search Transactions    ${tx}[code]
    ${row}=    Row With Text    ${tx}[returner]
    Wait For Elements State    ${row}    visible    timeout=15s
    RETURN    ${row}

Stat Should Be Greater Than
    [Arguments]    ${card}    ${before}
    ${now}=    Read Stat Count    ${card}
    Should Be True    ${now} > ${before}    ${card}: ${now} ต้องมากกว่า ${before}

First Row Should Not Be
    [Arguments]    ${previous}
    ${current}=    Get Text    ${TX_ROWS} >> nth=0
    Should Not Be Equal    ${current}    ${previous}

Return Pagination Item Should Be Active
    [Arguments]    ${number}
    Get Attribute    ${RETURN_SECTION} >> css=.ant-pagination-item-${number}    class    contains    ant-pagination-item-active


*** Test Cases ***
Header And Stat Cards Render
    [Documentation]    หัวหน้า "รายการคืนของวันนี้" + การ์ดสถิติ 4 ใบเป็นตัวเลข + หัวตาราง
    [Tags]    smoke
    Get Text    ${RETURN_HEADER}    contains    รายการคืนของวันนี้
    Get Text    ${RETURN_HEADER}    contains    จัดการและตรวจสอบรายการรับคืน
    Stat Card Should Show Count    ${RETURN_STAT_TOTAL}    รวมอุปกรณ์ต้องคืนวันนี้
    Stat Card Should Show Count    ${RETURN_STAT_COMPLETE}    คืนเรียบร้อยแล้ว
    Stat Card Should Show Count    ${RETURN_STAT_DAMAGED}    ของเสียหาย
    Stat Card Should Show Count    ${RETURN_STAT_HANDED_OUT}    อุปกรณ์ถูกจ่ายแล้ว
    Get Text    ${RETURN_SECTION}    matches    [\\d,]+ รายการอัปเดตล่าสุด
    FOR    ${column}    IN    เวลานัดคืน    ผู้ส่งคืนอุปกรณ์    สภาพอุปกรณ์    สถานะการคืน    การดำเนินการ
        Get Text    ${TX_TABLE} >> css=thead    contains    ${column}
    END
    Capture Page    80-return-stats

Stat Cards Count Today's Returns
    [Documentation]    สร้างรายการคืนสำเร็จ + รายการชำรุด (รอตรวจ) วันนี้ → การ์ดรวม/คืนแล้ว/ของเสียหาย เพิ่มขึ้น
    ${total}=    Read Stat Count    ${RETURN_STAT_TOTAL}
    ${complete}=    Read Stat Count    ${RETURN_STAT_COMPLETE}
    ${damaged}=    Read Stat Count    ${RETURN_STAT_DAMAGED}
    Create Return    complete
    Create Return    in_progress    ชำรุด / เสียหาย
    Reload Transactions Page
    Wait Until Keyword Succeeds    10x    1s    Stat Should Be Greater Than    ${RETURN_STAT_TOTAL}    ${total}
    Wait Until Keyword Succeeds    10x    1s    Stat Should Be Greater Than    ${RETURN_STAT_COMPLETE}    ${complete}
    Wait Until Keyword Succeeds    10x    1s    Stat Should Be Greater Than    ${RETURN_STAT_DAMAGED}    ${damaged}

Search Finds Return And Clear Restores List
    [Documentation]    ค้นหาด้วยรหัสรายการคืน → เหลือแถวเดียวพร้อมชื่อผู้คืน/อุปกรณ์ · ล้างช่องค้นหา → รายการกลับมา
    ${tx}=    Create Return
    Reload Transactions Page
    ${row}=    Find Return Row    ${tx}
    Wait Until Keyword Succeeds    10x    1s    Get Element Count    ${TX_ROWS}    ==    1
    Get Text    ${row}    contains    ${EQUIPMENT}[name]
    Get Text    ${row}    contains    1 ชิ้น
    Get Text    ${row}    contains    ปกติ (สมบูรณ์)
    Get Text    ${row} >> css=[data-testid="status-pending"]    ==    รอคืนของ
    Capture Page    81-return-search
    Click    css=[data-testid="tx-search"] .ant-input-clear-icon
    Wait Until Keyword Succeeds    10x    1s    Get Element Count    ${TX_ROWS}    >    1

Status Filter Shows Only Selected Status
    [Documentation]    ตัวกรองขั้นสูง → "คืนสำเร็จแล้ว" / "รอเจ้าหน้าที่ตรวจ" · "ทุกสถานะ" กลับเป็นป้ายเดิม
    Get Text    ${TX_STATUS}    contains    ตัวกรองขั้นสูง
    Choose Dropdown Option    ${TX_STATUS}    คืนสำเร็จแล้ว
    Get Text    ${TX_STATUS}    contains    คืนสำเร็จแล้ว
    Wait Until Keyword Succeeds    10x    1s    Every Visible Row Should Have Element    [data-testid="status-complete"]
    Get Element Count    ${TX_ROWS} >> ${TX_CONFIRM_RETURN}    ==    0
    Capture Page    82-return-filter-complete
    Choose Dropdown Option    ${TX_STATUS}    รอเจ้าหน้าที่ตรวจ
    Wait Until Keyword Succeeds    10x    1s    Every Visible Row Should Have Element    [data-testid="status-in_progress"]
    Choose Dropdown Option    ${TX_STATUS}    ทุกสถานะ
    Get Text    ${TX_STATUS}    contains    ตัวกรองขั้นสูง
    Transactions Page Should Be Loaded

Return Button Opens Intake Page
    [Documentation]    ปุ่ม "คืนของ" → /return/new
    Get Text    ${RETURN_NEW}    ==    คืนของ
    Click    ${RETURN_NEW}
    Url Should End With    /return/new
    Wait For Elements State    ${RI_PAGE}    visible    timeout=15s

Confirm Return Changes Status To Complete
    [Documentation]    ยืนยันรับคืน → modal แสดงอุปกรณ์/ผู้คืน → ยืนยัน → สถานะ "คืนสำเร็จแล้ว" และปุ่มเปลี่ยนเป็นดูรายละเอียด
    [Tags]    smoke
    ${tx}=    Create Return    pending
    Reload Transactions Page
    ${row}=    Find Return Row    ${tx}
    Click    ${row} >> ${TX_CONFIRM_RETURN}
    Wait For Elements State    ${RETURN_CONFIRM_MODAL}    visible    timeout=10s
    Get Text    ${RETURN_CONFIRM_MODAL}    contains    ต้องการยืนยันรับคืน ?
    Get Text    ${RETURN_CONFIRM_MODAL}    contains    ${EQUIPMENT}[name] จำนวน 1
    Get Text    ${RETURN_CONFIRM_MODAL}    contains    จาก ${tx}[returner]
    Capture Page    83-return-confirm-modal
    Click    ${RETURN_CONFIRM_OK}
    Wait For Elements State    ${RETURN_CONFIRM_MODAL}    detached    timeout=10s
    Message Should Appear    ยืนยันรับคืนแล้ว
    Wait For Elements State    ${row} >> css=[data-testid="status-complete"]    visible    timeout=15s
    Get Text    ${row} >> css=[data-testid="status-complete"]    ==    คืนสำเร็จแล้ว
    Get Text    ${row} >> ${TX_VIEW}    ==    ดูรายละเอียด
    Api Transaction Status Should Be    ${AUTH}    ${tx}[id]    complete
    Capture Page    84-return-confirmed

Cancelling Confirm Return Changes Nothing
    [Documentation]    กด "ยกเลิก" หรือปุ่ม X ใน modal → สถานะเดิม (รอเจ้าหน้าที่ตรวจ) และ API ไม่เปลี่ยน
    ${tx}=    Create Return    in_progress    มีรอยขีดข่วน
    Reload Transactions Page
    ${row}=    Find Return Row    ${tx}
    Get Text    ${row}    contains    มีรอยขีดข่วน
    Click    ${row} >> ${TX_CONFIRM_RETURN}
    Wait For Elements State    ${RETURN_CONFIRM_MODAL}    visible    timeout=10s
    Click    ${RETURN_CONFIRM_CANCEL}
    Wait For Elements State    ${RETURN_CONFIRM_MODAL}    detached    timeout=10s
    Click    ${row} >> ${TX_CONFIRM_RETURN}
    Wait For Elements State    ${RETURN_CONFIRM_MODAL}    visible    timeout=10s
    Close Open Modal
    Wait For Elements State    ${RETURN_CONFIRM_MODAL}    detached    timeout=10s
    Get Text    ${row} >> css=[data-testid="status-in_progress"]    ==    รอเจ้าหน้าที่ตรวจ
    Get Text    ${row} >> ${TX_CONFIRM_RETURN}    ==    ยืนยันรับคืน
    Api Transaction Status Should Be    ${AUTH}    ${tx}[id]    in_progress

Detail Modal Shows Return Information
    [Documentation]    ดูรายละเอียด → modal แสดงรหัส ผู้คืน อุปกรณ์ จำนวน สภาพ สถานะ บันทึก · ปิดด้วย X
    ${tx}=    Create Return    complete
    Reload Transactions Page
    ${row}=    Find Return Row    ${tx}
    Click    ${row} >> ${TX_VIEW}
    Wait For Elements State    ${RETURN_DETAIL}    visible    timeout=10s
    Get Text    css=.ant-modal-title >> text=รายละเอียดการคืน    ==    รายละเอียดการคืน
    Get Text    ${RETURN_DETAIL}    contains    ${tx}[code]
    Get Text    ${RETURN_DETAIL}    contains    ${tx}[returner]
    Get Text    ${RETURN_DETAIL}    contains    ${EQUIPMENT}[name] (${EQUIPMENT}[code])
    Get Text    ${RETURN_DETAIL}    contains    ปกติ (สมบูรณ์)
    Get Text    ${RETURN_DETAIL}    contains    คืนสำเร็จแล้ว
    Get Text    ${RETURN_DETAIL}    contains    อ้างอิง: ${tx}[borrow_code]
    Capture Page    85-return-detail-modal
    Close Open Modal
    Wait For Elements State    ${RETURN_DETAIL}    detached    timeout=10s

Pagination Moves Between Pages
    [Documentation]    แสดงยอดรวม · คลิกหน้า 2 → ข้อมูลเปลี่ยน · ปุ่มก่อนหน้า → กลับหน้า 1
    ${pagination}=    Set Variable    ${RETURN_SECTION} >> css=.ant-pagination
    Get Text    ${pagination}    matches    ทั้งหมด [\\d,]+ รายการ
    Return Pagination Item Should Be Active    1
    ${first}=    Get Text    ${TX_ROWS} >> nth=0
    Click    ${RETURN_SECTION} >> css=.ant-pagination-item-2
    Wait Until Keyword Succeeds    10x    1s    Return Pagination Item Should Be Active    2
    Wait Until Keyword Succeeds    10x    1s    First Row Should Not Be    ${first}
    Capture Page    86-return-page2
    Click    ${RETURN_SECTION} >> css=.ant-pagination-prev
    Wait Until Keyword Succeeds    10x    1s    Return Pagination Item Should Be Active    1
    Click    ${RETURN_SECTION} >> css=.ant-pagination-next
    Wait Until Keyword Succeeds    10x    1s    Return Pagination Item Should Be Active    2
