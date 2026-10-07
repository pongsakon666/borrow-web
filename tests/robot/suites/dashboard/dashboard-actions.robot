*** Settings ***
Documentation     ทดสอบทุก action บนหน้า Dashboard — การ์ดสรุป, เลือกช่วงเวลา (ยิง API ใหม่),
...               กราฟ, ครุภัณฑ์ยอดนิยม, ตารางรายการล่าสุด + เมนู "..." และแถบขวา
Resource          ../../resources/common.resource
Library           String
Suite Setup       Run Keywords    Open App    /login    AND    Start Fresh Session
Suite Teardown    Close App
Test Setup        Open Dashboard
Test Tags         dashboard    ui


*** Keywords ***
Open Dashboard
    Go To    ${BASE_URL}/
    Dashboard Should Be Loaded

Select Range And Expect Request
    [Arguments]    ${label}    ${value}
    [Documentation]    เลือกช่วงเวลาแล้วรอให้ FE ยิง /dashboard/summary?range=<value> จริง
    ${promise}=    Promise To    Wait For Response    matcher=/dashboard\\/summary\\?range=${value}/    timeout=15s
    Change Range To    ${label}
    ${resp}=    Wait For    ${promise}
    Should Be Equal As Integers    ${resp}[status]    200
    Range Should Be    ${label}
    Wait Until Keyword Succeeds    10x    1s    Stat Should Have Number    ${STAT_TOTAL}


*** Test Cases ***
Stat Cards Show Label Value And Trend
    [Documentation]    การ์ด 4 ใบ: ชื่อ + ตัวเลข + % เปลี่ยนแปลงพร้อมไอคอนขึ้น/ลง
    Get Element Count    ${STAT_GRID} >> css=.stat-card    ==    4
    FOR    ${key}    IN    total    borrowed    returned    available
        Stat Should Have Number    css=[data-testid="stat-${key}-value"]
        Stat Card Should Show Trend    ${key}
    END
    Capture Page    86-dashboard-stat-trend

Range Select Offers Four Options And Reloads Summary
    [Documentation]    ตัวเลือก Today / This week / This month / This year — เปลี่ยนแล้วยิง API ใหม่ทุกครั้ง
    Range Should Be    This month
    Click    ${DASHBOARD_RANGE}
    Wait For Elements State    css=.ant-select-dropdown    visible    timeout=10s
    FOR    ${label}    IN    Today    This week    This month    This year
        Wait For Elements State    css=.ant-select-item-option[title="${label}"]    visible
    END
    Keyboard Key    press    Escape
    Select Range And Expect Request    Today    today
    Select Range And Expect Request    This week    week
    Select Range And Expect Request    This year    year
    Capture Page    87-dashboard-range-year
    # This month ถูกโหลดไว้แล้วตอนเปิดหน้า (staleTime 30s) — อาจใช้ cache ไม่ยิงซ้ำ จึงตรวจแค่ค่าบนหน้าจอ
    Change Range To    This month
    Range Should Be    This month
    Wait Until Keyword Succeeds    10x    1s    Stat Should Have Number    ${STAT_TOTAL}
    [Teardown]    Run Keyword And Ignore Error    Change Range To    This month

Usage And Yearly Charts Are Drawn
    [Documentation]    กราฟ "การใช้งาน" (พื้นที่ + เส้นประ) และ "สถิติประจำปี" (แท่ง 12 เดือน)
    Charts Should Be Rendered
    Get Text    css=.dashboard__charts    contains    การใช้งาน
    Get Text    css=.dashboard__body    contains    สถิติประจำปี
    Wait For Elements State    css=.recharts-area-area >> nth=0    attached    timeout=10s
    Wait For Elements State    css=.recharts-line-curve >> nth=0    attached    timeout=10s
    ${bars}=    Get Element Count    css=.recharts-bar-rectangle
    Should Be True    ${bars} >= 12    กราฟแท่งต้องมีอย่างน้อย 12 แท่ง (ได้ ${bars})
    ${ticks}=    Get Element Count    css=.recharts-xAxis .recharts-cartesian-axis-tick
    Should Be True    ${ticks} > 0

Popular List Shows Names With Bars
    Wait For Elements State    ${POPULAR_LIST}    visible    timeout=15s
    ${items}=    Get Element Count    ${POPULAR_LIST} >> css=li
    Should Be True    ${items} > 0
    FOR    ${i}    IN RANGE    ${items}
        ${name}=    Get Text    ${POPULAR_LIST} >> css=li >> nth=${i} >> css=.popular-list__name
        Should Not Be Empty    ${name}
        Get Element Count    ${POPULAR_LIST} >> css=li >> nth=${i} >> css=.popular-list__bar i    ==    3
    END

Recent Table Has Columns And Status Chips
    [Documentation]    หัวตาราง 6 คอลัมน์ และทุกแถวมีชิปสถานะ
    Recent Table Should Have Rows
    FOR    ${col}    IN    ชื่อ    ครุภัณฑ์    รหัสครุภัณฑ์    ประเภท    วันที่    สถานะการดำเนินการ
        Get Text    ${RECENT_TABLE} >> css=thead    contains    ${col}
    END
    ${rows}=    Get Element Count    ${RECENT_ROWS}
    Get Element Count    ${RECENT_ROWS} >> css=.status-chip    ==    ${rows}

Recent More Menu Opens Borrow List
    [Documentation]    ปุ่ม "..." → ดูรายการยืมทั้งหมด → /borrow
    Open Recent More Menu
    Get Element Count    ${DROPDOWN_ITEM}    ==    2
    Capture Page    88-dashboard-recent-more
    Click    ${DROPDOWN_ITEM} >> text=ดูรายการยืมทั้งหมด
    Url Should Be    /borrow
    Wait Until Keyword Succeeds    5x    1s    Page Title Should Be    Borrow

Recent More Menu Opens Return List
    [Documentation]    ปุ่ม "..." → ดูรายการคืนทั้งหมด → /return
    Choose Recent More Item    ดูรายการคืนทั้งหมด
    Url Should Be    /return
    Wait Until Keyword Succeeds    5x    1s    Page Title Should Be    Return

Right Rail Sections Have Titles And Rows
    [Documentation]    การแจ้งเตือน / ประวัติการทำรายการ / สมาชิก — หัวข้อถูกต้องและมีข้อมูล
    Get Text    ${RAIL_NOTIFICATIONS} >> css=.rail-section__title    ==    การแจ้งเตือน
    Get Text    ${RAIL_ACTIVITIES} >> css=.rail-section__title    ==    ประวัติการทำรายการในระบบ
    Get Text    ${RAIL_MEMBERS} >> css=.rail-section__title    ==    สมาชิก
    FOR    ${rail}    IN    ${RAIL_NOTIFICATIONS}    ${RAIL_ACTIVITIES}    ${RAIL_MEMBERS}
        Wait Until Keyword Succeeds    10x    1s    Rail Should Have Rows    ${rail}
    END
    # กล่องแจ้งเตือน/ประวัติต้องมีเวลาแบบ relative ทุกแถว
    ${n}=    Get Element Count    ${RAIL_ACTIVITIES} >> css=.rail-row
    Get Element Count    ${RAIL_ACTIVITIES} >> css=.rail-row small    ==    ${n}
    ${members}=    Get Element Count    ${RAIL_MEMBERS} >> css=.rail-row
    Should Be True    ${members} <= 6    สมาชิกแสดงไม่เกิน 6 คน


*** Keywords ***
Rail Should Have Rows
    [Arguments]    ${rail}
    ${rows}=    Get Element Count    ${rail} >> css=.rail-row
    Should Be True    ${rows} > 0
