*** Settings ***
Documentation     Page Object ของหน้า Dashboard
Library           Browser
Library           String
Variables         ../variables.py


*** Variables ***
${DASHBOARD}           css=[data-testid="dashboard-page"]
${DASHBOARD_RANGE}     css=[data-testid="dashboard-range"]
${STAT_GRID}           css=[data-testid="stat-grid"]
${STAT_TOTAL}          css=[data-testid="stat-total-value"]
${STAT_BORROWED}       css=[data-testid="stat-borrowed-value"]
${STAT_RETURNED}       css=[data-testid="stat-returned-value"]
${STAT_AVAILABLE}      css=[data-testid="stat-available-value"]
${POPULAR_LIST}        css=[data-testid="popular-list"]
${RECENT_TABLE}        css=[data-testid="recent-table"]
${RAIL_NOTIFICATIONS}  css=[data-testid="rail-notifications"]
${RAIL_ACTIVITIES}     css=[data-testid="rail-activities"]
${RAIL_MEMBERS}        css=[data-testid="rail-members"]
${CHART_SVG}           css=.recharts-surface


*** Keywords ***
Dashboard Should Be Loaded
    [Documentation]    รอจนการ์ดสรุปมีตัวเลขจริง (ไม่ใช่ skeleton)
    Wait For Elements State    ${DASHBOARD}    visible    timeout=20s
    Wait For Elements State    ${STAT_TOTAL}    visible    timeout=20s
    Wait Until Keyword Succeeds    10x    1s    Stat Should Have Number    ${STAT_TOTAL}

Stat Should Have Number
    [Arguments]    ${locator}
    [Documentation]    ตัวเลขบนการ์ดมี comma คั่นหลักพัน — ตัดออกก่อนแปลงเป็น int
    ...                ถ้ายังเป็น skeleton จะแปลงไม่ผ่านแล้ว retry ต่อ
    ${text}=    Get Text    ${locator}
    Should Not Be Empty    ${text}
    ${clean}=    Replace String    ${text}    ,    ${EMPTY}
    ${number}=    Convert To Integer    ${clean}
    Should Be True    ${number} >= 0

Charts Should Be Rendered
    [Documentation]    recharts วาด <svg class="recharts-surface"> — ต้องมีอย่างน้อย 2 กราฟ
    ${count}=    Get Element Count    ${CHART_SVG}
    Should Be True    ${count} >= 2    ต้องมีกราฟอย่างน้อย 2 รูป แต่พบ ${count}

Recent Table Should Have Rows
    ${rows}=    Get Element Count    ${RECENT_TABLE} >> css=tbody tr.ant-table-row
    Should Be True    ${rows} > 0    ตารางรายการล่าสุดต้องมีข้อมูล

Change Range To
    [Arguments]    ${label}
    Click    ${DASHBOARD_RANGE}
    Click    css=.ant-select-item-option[title="${label}"]

# ── ส่วนเพิ่มเติมสำหรับ suites/dashboard/dashboard-actions.robot ──
*** Variables ***
${RECENT_MORE}         css=[data-testid="recent-more"]
${RECENT_ROWS}         css=[data-testid="recent-table"] >> css=tbody tr.ant-table-row
${DROPDOWN_ITEM}       css=.ant-dropdown:not(.ant-dropdown-hidden) .ant-dropdown-menu-item
${RANGE_SELECTED}      css=[data-testid="dashboard-range"] .ant-select-content


*** Keywords ***
Range Should Be
    [Arguments]    ${label}
    [Documentation]    ข้อความที่แสดงอยู่ใน Select ช่วงเวลา
    Get Text    ${DASHBOARD_RANGE}    contains    ${label}

Open Recent More Menu
    [Documentation]    ปุ่ม "..." ของตารางรายการล่าสุด → dropdown 2 ตัวเลือก
    Click    ${RECENT_MORE}
    Wait For Elements State    ${DROPDOWN_ITEM} >> nth=0    visible    timeout=10s

Choose Recent More Item
    [Arguments]    ${label}
    Open Recent More Menu
    Click    ${DROPDOWN_ITEM} >> text=${label}

Stat Card Should Show Trend
    [Arguments]    ${key}
    [Documentation]    การ์ดสรุปต้องมีเปอร์เซ็นต์เปลี่ยนแปลง + ไอคอนขึ้น/ลง
    Get Text    css=[data-testid="stat-${key}"] .stat-trend    contains    %
    Get Element Count    css=[data-testid="stat-${key}"] .stat-trend .anticon    ==    1
