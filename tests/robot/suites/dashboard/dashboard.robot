*** Settings ***
Documentation     ทดสอบหน้า Dashboard — การ์ดสรุป กราฟ ตาราง และแถบขวา ต้องผูกกับ API จริง
Resource          ../../resources/common.resource
Library           String
Suite Setup       Run Keywords    Open App    /login    AND    Start Fresh Session
Suite Teardown    Close App
Test Tags         dashboard    ui


*** Test Cases ***
Summary Cards Show Numbers From API
    [Documentation]    การ์ด 4 ใบต้องมีตัวเลขจริง ไม่ใช่ค่าว่างหรือ skeleton
    [Tags]    smoke
    Dashboard Should Be Loaded
    FOR    ${stat}    IN    ${STAT_TOTAL}    ${STAT_BORROWED}    ${STAT_RETURNED}    ${STAT_AVAILABLE}
        Stat Should Have Number    ${stat}
    END
    Get Text    css=[data-testid="stat-total"]    contains    ครุภัณฑ์ทั้งหมด
    Get Text    css=[data-testid="stat-borrowed"]    contains    ยืมครุภัณฑ์
    Get Text    css=[data-testid="stat-returned"]    contains    คืนครุภัณฑ์
    Get Text    css=[data-testid="stat-available"]    contains    ครุภัณฑ์คงเหลือ
    Capture Page    20-dashboard-stats

Available Equals Total Minus Borrowed
    [Documentation]    ตัวเลขบนการ์ดต้องสอดคล้องกันเอง — คงเหลือ = ทั้งหมด - ที่ถูกยืม
    ${total}=    Get Number From Stat    ${STAT_TOTAL}
    ${borrowed}=    Get Number From Stat    ${STAT_BORROWED}
    ${available}=    Get Number From Stat    ${STAT_AVAILABLE}
    Should Be Equal As Integers    ${available}    ${${total} - ${borrowed}}

Charts Are Rendered
    [Documentation]    กราฟเส้น "การใช้งาน" และกราฟแท่ง "สถิติประจำปี" ต้องวาดจริง
    Charts Should Be Rendered
    Wait For Elements State    ${POPULAR_LIST}    visible    timeout=15s
    ${items}=    Get Element Count    ${POPULAR_LIST} >> css=li
    Should Be True    ${items} > 0    รายการครุภัณฑ์ยอดนิยมต้องไม่ว่าง

Recent Transactions Table Has Data
    [Documentation]    ตารางรายการล่าสุดต้องมีข้อมูลและมี tag สถานะ
    Recent Table Should Have Rows
    ${tags}=    Get Element Count    ${RECENT_TABLE} >> css=.ant-tag
    Should Be True    ${tags} > 0    ต้องมี tag สถานะในตาราง
    Capture Page    21-dashboard-recent

Right Rail Shows Notifications Activities And Members
    [Documentation]    แถบขวา 3 กล่องต้องมีข้อมูลจาก API
    FOR    ${rail}    IN    ${RAIL_NOTIFICATIONS}    ${RAIL_ACTIVITIES}    ${RAIL_MEMBERS}
        Wait For Elements State    ${rail}    visible    timeout=15s
        ${rows}=    Get Element Count    ${rail} >> css=.rail-row
        Should Be True    ${rows} > 0    กล่อง ${rail} ต้องมีข้อมูล
    END
    Get Text    ${RAIL_MEMBERS}    contains    ${SEED_MEMBER}
    Capture Page    22-dashboard-rail

Changing Range Reloads Summary
    [Documentation]    เปลี่ยนช่วงเวลา → ตัวเลขถูกโหลดใหม่ (ยังเป็นตัวเลขที่อ่านได้)
    Change Range To    This year
    Wait Until Keyword Succeeds    10x    1s    Stat Should Have Number    ${STAT_TOTAL}
    Capture Page    23-dashboard-range-year
    [Teardown]    Change Range To    This month


*** Keywords ***
Get Number From Stat
    [Arguments]    ${locator}
    [Documentation]    อ่านตัวเลขจากการ์ด ตัด comma ออกเพื่อเทียบเชิงเลข
    ${text}=    Get Text    ${locator}
    ${clean}=    Replace String    ${text}    ,    ${EMPTY}
    ${number}=    Convert To Integer    ${clean}
    RETURN    ${number}
