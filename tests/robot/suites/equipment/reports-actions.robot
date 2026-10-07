*** Settings ***
Documentation     ทดสอบทุก action บนหน้า Product Reports — การ์ด KPI, กราฟแท่ง + donut,
...               เลือกช่วงวันที่, ส่งออก CSV, กรองสถานะ ("กรองตาราง"), กรองประเภท, ค้นหา, แบ่งหน้า
Resource          ../../resources/common.resource
Library           OperatingSystem
Library           String
Suite Setup       Run Keywords    Open App    /login    AND    Start Fresh Session
Suite Teardown    Close App
Test Setup        Open Reports
Test Tags         equipment    reports    ui


*** Keywords ***
Open Reports
    Go To    ${BASE_URL}/reports
    Reports Page Should Be Loaded

Number From
    [Arguments]    ${locator}
    ${text}=    Get Text    ${locator}
    ${clean}=    Replace String    ${text}    ,    ${EMPTY}
    ${n}=    Convert To Integer    ${clean}
    RETURN    ${n}

Every Row Should Have Status
    [Arguments]    ${status}
    ${rows}=    Get Element Count    ${EQ_ROWS}
    Should Be True    ${rows} > 0
    Get Element Count    ${EQ_ROWS} >> css=[data-testid="eq-status-${status}"]    ==    ${rows}

Every Row Should Contain Text
    [Arguments]    ${text}
    ${rows}=    Get Element Count    ${EQ_ROWS}
    Should Be True    ${rows} > 0
    FOR    ${i}    IN RANGE    ${rows}
        Get Text    ${EQ_ROWS} >> nth=${i}    contains    ${text}
    END

Row Count Should Be
    [Arguments]    ${expected}
    Get Element Count    ${EQ_ROWS}    ==    ${expected}

Total Text Number
    ${text}=    Get Text    ${EQ_PAGINATION} >> css=.ant-pagination-total-text
    ${n}=    Evaluate    int(''.join(c for c in $text if c.isdigit()))
    RETURN    ${n}

First Row Should Not Be
    [Arguments]    ${previous}
    ${now}=    Get Text    ${EQ_ROWS} >> nth=0
    Should Not Be Equal    ${now}    ${previous}


*** Test Cases ***
Kpi Cards Show Numbers
    [Documentation]    การ์ด 4 ใบ: สินค้าทั้งหมด / ยืมทั้งหมด / คืนแล้ว / เสียหาย
    FOR    ${id}    ${label}    IN
    ...    report-total    สินค้าทั้งหมด
    ...    report-borrowed    ยืมทั้งหมด
    ...    report-returned    คืนแล้ว
    ...    report-damaged    เสียหาย
        Get Text    css=[data-testid="${id}"]    contains    ${label}
        Wait Until Keyword Succeeds    10x    1s    Report Kpi Should Have Number    ${id}
    END
    Get Text    css=[data-testid="report-total"]    contains    % พร้อมใช้
    Get Text    css=[data-testid="report-borrowed"]    contains    จากช่วงก่อน
    Get Text    css=[data-testid="report-damaged"]    contains    รายการซ่อมแซม
    Capture Page    93-reports-kpi

Trend Bar Chart And Status Donut Are Drawn
    [Documentation]    กราฟแท่งยืม-คืน 6 เดือน + donut สัดส่วนสถานะ ที่ยอดรวมตรงกับการ์ด "สินค้าทั้งหมด"
    Wait For Elements State    ${REPORT_TREND} >> css=.recharts-surface    visible    timeout=15s
    Get Text    ${REPORT_TREND}    contains    ยืม
    Get Text    ${REPORT_TREND}    contains    คืน
    Wait For Condition    Element Count    ${REPORT_TREND} >> css=.recharts-xAxis .recharts-cartesian-axis-tick    ==    6    timeout=15s
    Wait For Elements State    ${REPORT_STATUS} >> css=.recharts-pie-sector >> nth=0    attached    timeout=15s
    Get Element Count    ${REPORT_STATUS} >> css=.rp-legend li    ==    4
    Wait Until Keyword Succeeds    10x    1s    Donut Total Should Match Kpi
    ${legend_sum}=    Set Variable    ${0}
    FOR    ${i}    IN RANGE    4
        ${n}=    Number From    ${REPORT_STATUS} >> css=.rp-legend li >> nth=${i} >> css=b
        ${legend_sum}=    Evaluate    ${legend_sum} + ${n}
    END
    ${total}=    Number From    css=[data-testid="report-total-value"]
    Should Be Equal As Integers    ${legend_sum}    ${total}

Changing Date Range Reloads Borrow And Return Counts
    [Documentation]    เลือกช่วงวันที่ใหม่ใน RangePicker → ช่องแสดงวันที่เปลี่ยน และยิง API นับยืม/คืนใหม่
    ${before}=    Get Property    ${REPORT_RANGE_START}    value
    ${ym}=    Get Time    year month    NOW
    ${start}=    Set Variable    ${ym}[0]-${ym}[1]-05
    ${end}=    Set Variable    ${ym}[0]-${ym}[1]-20
    ${promise}=    Promise To    Wait For Response    matcher=/\\/transactions\\?type=borrow&from=/    timeout=15s
    Pick Report Range    ${start}    ${end}
    Wait For    ${promise}
    ${after}=    Get Property    ${REPORT_RANGE_START}    value
    Should Not Be Equal    ${after}    ${before}
    Should Start With    ${after}    5${SPACE}
    Get Property    ${REPORT_RANGE_END}    value    starts    20${SPACE}
    Wait Until Keyword Succeeds    10x    1s    Report Kpi Should Have Number    report-borrowed
    Capture Page    94-reports-range-changed

Export Downloads Csv With Header And Rows
    [Documentation]    ปุ่ม Export → ดาวน์โหลด product-report-YYYYMMDD.csv = header + แถวที่แสดงในตาราง
    ${rows}=    Get Element Count    ${EQ_ROWS}
    ${promise}=    Promise To Wait For Download    ${OUTPUT DIR}${/}downloads${/}product-report.csv
    Click    ${REPORT_EXPORT}
    ${file}=    Wait For    ${promise}
    Should Match Regexp    ${file}[suggestedFilename]    ^product-report-\\d{8}\\.csv$
    File Should Exist    ${file}[saveAs]
    ${content}=    Get File    ${file}[saveAs]    encoding=UTF-8
    ${content}=    Replace String    ${content}    ﻿    ${EMPTY}
    ${lines}=    Split To Lines    ${content}
    Should Be Equal    ${lines}[0]    "รหัสสินค้า","ชื่อสินค้า","ประเภท","สถานะ","ผู้ยืม","วันที่ยืม","วันที่คืน"
    Length Should Be    ${lines}    ${rows + 1}
    ${first_code}=    Get Text    ${EQ_ROWS} >> nth=0 >> css=.rp-code
    Should Start With    ${lines}[1]    "${first_code}",

Status Filter Shows Only That Status
    [Documentation]    ปุ่ม "กรองตาราง" → เลือก "ว่าง (พร้อมใช้)" → ทุกแถวสถานะ ready · เลือก "ทุกสถานะ" → กลับเหมือนเดิม
    Get Text    ${EQ_STATUS_FILTER}    ==    กรองตาราง
    Filter Equipment By Status    ว่าง (พร้อมใช้)
    Wait Until Keyword Succeeds    10x    1s    Every Row Should Have Status    ready
    Get Text    ${EQ_STATUS_FILTER}    ==    ว่าง (พร้อมใช้)
    Get Attribute    ${EQ_STATUS_FILTER}    class    contains    is-active
    Capture Page    95-reports-status-filter
    Filter Equipment By Status    ทุกสถานะ
    Wait For Condition    Text    ${EQ_STATUS_FILTER}    ==    กรองตาราง    timeout=10s
    Get Attribute    ${EQ_STATUS_FILTER}    class    not contains    is-active

Category Filter And Reset
    Click    ${EQ_CATEGORY}
    Click    css=.ant-select-dropdown:not(.ant-select-dropdown-hidden) .ant-select-item-option[title="${SEED_CATEGORY}"]
    Wait For Condition    Text    ${EQ_CATEGORY}    contains    ${SEED_CATEGORY}    timeout=10s
    Wait Until Keyword Succeeds    15x    1s    Every Row Should Contain Text    ${SEED_CATEGORY}
    ${filtered}=    Total Text Number
    Click    ${EQ_CATEGORY}
    Click    css=.ant-select-dropdown:not(.ant-select-dropdown-hidden) .ant-select-item-option[title="ทุกประเภท"]
    Wait Until Keyword Succeeds    10x    1s    Total Should Be Greater Than    ${filtered}

Search Then Clear Restores List
    ${all}=    Total Text Number
    Fill Text    ${EQ_SEARCH} >> css=input    ${SEED_EQUIPMENT_CODE}
    Keyboard Key    press    Enter
    Wait Until Keyword Succeeds    10x    1s    Row Count Should Be    1
    Click    ${EQ_SEARCH} >> css=.ant-input-clear-icon
    Wait Until Keyword Succeeds    10x    1s    Total Should Be Equal    ${all}

Search Without Match Shows Empty Table
    Fill Text    ${EQ_SEARCH} >> css=input    ไม่มีครุภัณฑ์นี้แน่นอน-zzz
    Keyboard Key    press    Enter
    Wait For Elements State    ${EQ_TABLE} >> css=.ant-empty    visible    timeout=10s
    Get Element Count    ${EQ_ROWS}    ==    0

Pagination Next Previous And Page Number
    [Documentation]    หน้าละ 10 แถว · คลิกเลข 2 / ปุ่มถัดไป / ก่อนหน้า แล้วข้อมูลเปลี่ยนตามหน้า
    ${total}=    Total Text Number
    Should Be True    ${total} > 10    ต้องมีข้อมูลมากกว่า 1 หน้า
    Row Count Should Be    10
    ${first}=    Get Text    ${EQ_ROWS} >> nth=0
    Click    ${EQ_PAGINATION} >> css=.ant-pagination-item-2
    Wait Until Keyword Succeeds    10x    1s    First Row Should Not Be    ${first}
    Get Attribute    ${EQ_PAGINATION} >> css=.ant-pagination-item-2    class    contains    ant-pagination-item-active
    Click    ${EQ_PAGINATION} >> css=.ant-pagination-prev
    Wait For Condition    Attribute    ${EQ_PAGINATION} >> css=.ant-pagination-item-1    class    contains    ant-pagination-item-active    timeout=10s
    Wait Until Keyword Succeeds    10x    1s    First Row Should Be    ${first}
    Click    ${EQ_PAGINATION} >> css=.ant-pagination-next
    Wait For Condition    Attribute    ${EQ_PAGINATION} >> css=.ant-pagination-item-2    class    contains    ant-pagination-item-active    timeout=10s

Add Product Button Opens Wizard
    Click    ${EQ_ADD}
    Wait For Elements State    ${WIZARD}    visible    timeout=15s
    Url Should Be    /equipment/new
    Only This Nav Should Be Highlighted    ${NAV_ADD_PRODUCT}


*** Keywords ***
Donut Total Should Match Kpi
    ${center}=    Number From    ${REPORT_STATUS} >> css=.rp-donut__center strong
    ${kpi}=    Number From    css=[data-testid="report-total-value"]
    Should Be Equal As Integers    ${center}    ${kpi}
    Should Be True    ${kpi} > 0

Total Should Be Greater Than
    [Arguments]    ${n}
    ${now}=    Total Text Number
    Should Be True    ${now} > ${n}

Total Should Be Equal
    [Arguments]    ${n}
    ${now}=    Total Text Number
    Should Be Equal As Integers    ${now}    ${n}

First Row Should Be
    [Arguments]    ${expected}
    ${now}=    Get Text    ${EQ_ROWS} >> nth=0
    Should Be Equal    ${now}    ${expected}
