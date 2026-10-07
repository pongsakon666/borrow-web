*** Settings ***
Documentation     ทดสอบหน้า Borrow / Return — ตาราง ค้นหา กรองสถานะ และแบ่งหน้า
Resource          ../../resources/common.resource
Suite Setup       Run Keywords    Open App    /login    AND    Start Fresh Session
Suite Teardown    Close App
Test Tags         transactions    ui


*** Test Cases ***
Borrow Page Lists Transactions
    [Tags]    smoke
    Go To    ${BASE_URL}/borrow
    Transactions Page Should Be Loaded
    Get Text    css=[data-testid="borrow-header"]    contains    รายการยืมวันนี้
    Capture Page    40-borrow-list

Borrow Page Shows Due Date Column
    [Documentation]    หน้ายืมแสดง "กำหนดคืน" ใต้ชื่ออุปกรณ์ · หน้าคืนมีคอลัมน์ "อุปกรณ์ที่ครบกำหนดคืน"
    Go To    ${BASE_URL}/borrow
    Transactions Page Should Be Loaded
    Get Text    ${TX_TABLE}    contains    กำหนดคืน
    Go To    ${BASE_URL}/return
    Transactions Page Should Be Loaded
    Get Text    ${TX_TABLE}    contains    อุปกรณ์ที่ครบกำหนดคืน

Search Filters The Table
    [Documentation]    ค้นหาด้วยชื่อสมาชิกจาก seed → ทุกแถวต้องเป็นของคนนั้น
    Go To    ${BASE_URL}/borrow
    Transactions Page Should Be Loaded
    Search Transactions    ${SEED_MEMBER}
    Wait Until Keyword Succeeds    10x    1s    Every Row Should Contain    ${SEED_MEMBER}
    Capture Page    41-borrow-search

Filter By Status Shows Only That Status
    [Documentation]    กรองสถานะ Complete → ต้องเหลือเฉพาะ tag Complete
    Go To    ${BASE_URL}/borrow
    Transactions Page Should Be Loaded
    Filter By Status    Complete
    Wait Until Keyword Succeeds    10x    1s    Every Row Should Contain    Complete
    Capture Page    42-borrow-filter-status

Pagination Moves To Next Page
    [Documentation]    ไปหน้า 2 แล้วข้อมูลต้องเปลี่ยน
    Go To    ${BASE_URL}/borrow
    Transactions Page Should Be Loaded
    ${first_before}=    Get Text    ${TX_ROWS} >> nth=0
    Click    css=.ant-pagination-item-2
    Wait Until Keyword Succeeds    10x    1s    First Row Should Differ From    ${first_before}
    Capture Page    43-borrow-page2

Return Page Lists Transactions
    Go To    ${BASE_URL}/return
    Transactions Page Should Be Loaded
    Get Text    css=[data-testid="return-header"]    contains    รายการคืนของวันนี้
    Get Text    css=[data-testid="return-section-title"]    contains    Daily Return Transactions
    Capture Page    44-return-list


*** Keywords ***
Every Row Should Contain
    [Arguments]    ${text}
    ${rows}=    Get Element Count    ${TX_ROWS}
    Should Be True    ${rows} > 0    ต้องมีอย่างน้อย 1 แถวหลังกรอง
    FOR    ${i}    IN RANGE    ${rows}
        Get Text    ${TX_ROWS} >> nth=${i}    contains    ${text}
    END

First Row Should Differ From
    [Arguments]    ${previous}
    ${current}=    Get Text    ${TX_ROWS} >> nth=0
    Should Not Be Equal    ${current}    ${previous}
