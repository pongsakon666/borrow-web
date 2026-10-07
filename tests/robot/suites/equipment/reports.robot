*** Settings ***
Documentation     ทดสอบหน้า Product Reports — ตารางครุภัณฑ์ ค้นหา และกรองตามประเภท
Resource          ../../resources/common.resource
Suite Setup       Run Keywords    Open App    /login    AND    Start Fresh Session
Suite Teardown    Close App
Test Setup        Open Reports Page
Test Tags         equipment    reports    ui


*** Keywords ***
Open Reports Page
    Go To    ${BASE_URL}/reports
    Wait For Elements State    ${EQ_LIST}    visible    timeout=20s
    Wait Until Keyword Succeeds    10x    1s    Equipment Table Should Have Rows

Equipment Table Should Have Rows
    ${rows}=    Get Element Count    ${EQ_TABLE} >> css=tbody tr.ant-table-row
    Should Be True    ${rows} > 0    ตารางครุภัณฑ์ต้องมีข้อมูล


*** Test Cases ***
Equipment Table Shows Seeded Data
    [Tags]    smoke
    [Documentation]    ตารางเรียงรายการใหม่ก่อน — ครุภัณฑ์ที่เทสต์อื่นสร้างสะสมจะดัน seed ตกหน้า 1
    ...                จึงค้นหาด้วยชื่อ seed ก่อน แล้วตรวจว่าชื่อและรหัสจาก API แสดงในตาราง
    Fill Text    ${EQ_SEARCH} >> css=input    ${SEED_EQUIPMENT_NAME}
    Keyboard Key    press    Enter
    Wait Until Keyword Succeeds    10x    1s    Get Text    ${EQ_TABLE}    contains    ${SEED_EQUIPMENT_NAME}
    Get Text    ${EQ_TABLE}    contains    ${SEED_EQUIPMENT_CODE}
    Capture Page    50-reports-list

Search By Code Narrows Results
    Fill Text    ${EQ_SEARCH} >> css=input    ${SEED_EQUIPMENT_CODE}
    Keyboard Key    press    Enter
    Wait Until Keyword Succeeds    10x    1s    Only One Row Should Remain
    Get Text    ${EQ_TABLE}    contains    ${SEED_EQUIPMENT_NAME}
    Capture Page    51-reports-search

Filter By Category
    [Documentation]    เลือกประเภทแล้วทุกแถวต้องเป็นประเภทนั้น
    Click    ${EQ_CATEGORY}
    Wait For Elements State    css=.ant-select-dropdown    visible    timeout=10s
    Click    css=.ant-select-item-option[title="${SEED_CATEGORY}"]
    Wait Until Keyword Succeeds    10x    1s    Every Equipment Row Should Contain    ${SEED_CATEGORY}
    Capture Page    52-reports-filter-category

Add Button Opens Wizard
    Click    ${EQ_ADD}
    Wait For Elements State    ${WIZARD}    visible    timeout=15s
    Page Title Should Be    Add Products


*** Keywords ***
Only One Row Should Remain
    ${rows}=    Get Element Count    ${EQ_TABLE} >> css=tbody tr.ant-table-row
    Should Be Equal As Integers    ${rows}    1

Every Equipment Row Should Contain
    [Arguments]    ${text}
    ${rows}=    Get Element Count    ${EQ_TABLE} >> css=tbody tr.ant-table-row
    Should Be True    ${rows} > 0
    FOR    ${i}    IN RANGE    ${rows}
        Get Text    ${EQ_TABLE} >> css=tbody tr.ant-table-row >> nth=${i}    contains    ${text}
    END
