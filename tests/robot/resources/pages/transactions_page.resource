*** Settings ***
Documentation     Page Object ของหน้า Borrow / Return (+ ฟอร์ม /borrow/new และ /return/new)
Library           Browser
Library           RequestsLibrary
Library           Collections
Variables         ../variables.py


*** Variables ***
${TX_PAGE}       css=[data-testid="transactions-page"]
${TX_TABLE}      css=[data-testid="tx-table"]
${TX_SEARCH}     css=[data-testid="tx-search"] >> css=input
${TX_STATUS}     css=[data-testid="tx-status"]
${TX_ROWS}       css=[data-testid="tx-table"] >> css=tbody tr.ant-table-row

${TX_API}                  ${API_URL}/api/v1
${OPEN_DROPDOWN}           css=.ant-select-dropdown:not(.ant-select-dropdown-hidden)
${ANT_MODAL_CLOSE}         css=.ant-modal-wrap:visible .ant-modal-close
${TX_MESSAGE}              css=.ant-message-notice

# ── /borrow ──
${BORROW_HEADER}           css=[data-testid="borrow-header"]
${BORROW_ADD}              css=[data-testid="borrow-add"]
${BORROW_STAT_TOTAL}       css=[data-testid="borrow-stat-total"]
${BORROW_STAT_BOOKING}     css=[data-testid="borrow-stat-booking"]
${BORROW_STAT_WALKIN}      css=[data-testid="borrow-stat-walkin"]
${BORROW_STAT_ISSUED}      css=[data-testid="borrow-stat-issued"]
${BORROW_SECTION_BOOKING}  css=[data-testid="borrow-booking"]
${BORROW_SECTION_WALKIN}   css=[data-testid="borrow-walkin"]
${BORROW_PAGINATION}       css=.borrow-pagination
${VIEW_TABLE_BTN}          css=button[aria-label="มุมมองตาราง"]
${VIEW_LIST_BTN}           css=button[aria-label="มุมมองรายการ"]
${TX_ISSUE}                css=[data-testid="tx-issue"]
${TX_RETURN}               css=[data-testid="tx-return"]
${TX_DETAIL}               css=[data-testid="tx-detail"]
${TX_DETAIL_MODAL}         css=[data-testid="tx-detail-modal"]
${TX_ACTION_CONFIRM}       css=[data-testid="tx-action-confirm"]
${TX_ACTION_OK}            css=[data-testid="tx-action-confirm-ok"]
${TX_ACTION_CANCEL}        css=[data-testid="tx-action-confirm-cancel"]

# ── /borrow/new ──
${BF_PAGE}                 css=[data-testid="borrow-form-page"]
${BF_BACK}                 css=[data-testid="borrow-form-back"]
${BF_BOOKER}               css=[data-testid="borrow-booker"] >> css=input
${BF_PHONE}                css=[data-testid="borrow-phone"]
${BF_DEPARTMENT}           css=[data-testid="borrow-department"]
${BF_DATE}                 css=[data-testid="borrow-date"]
${BF_CHANNEL}              css=[data-testid="borrow-channel"]
${BF_SCAN}                 css=[data-testid="borrow-scan"]
${BF_SCAN_INPUT}           css=[data-testid="borrow-scan-input"]
${BF_EQUIPMENT}            css=[data-testid="borrow-equipment"]
${BF_EQUIPMENT_INPUT}      css=[data-testid="borrow-equipment"] >> css=input
${BF_EQUIPMENT_NAME}       css=[data-testid="borrow-equipment-name"]
${BF_EQUIPMENT_CODE}       css=[data-testid="borrow-equipment-code"]
${BF_QUANTITY}             css=[data-testid="borrow-quantity"]
${BF_QTY_MINUS}            css=button[aria-label="ลดจำนวน"]
${BF_QTY_PLUS}             css=button[aria-label="เพิ่มจำนวน"]
${BF_QTY_DISPLAY}          css=.borrow-qty__stepper > span
${BF_COLOR}                css=[data-testid="borrow-color"]
${BF_CATEGORY}             css=[data-testid="borrow-category"]
${BF_SUBCATEGORY}          css=[data-testid="borrow-subcategory"]
${BF_DETAILS}              css=[data-testid="borrow-details"]
${BF_REMARK}               css=[data-testid="borrow-remark"]
${BF_SUBMIT}               css=[data-testid="borrow-submit"]
${BF_DRAFT}                css=[data-testid="borrow-draft"]
${BF_CANCEL}               css=[data-testid="borrow-cancel"]
${BF_CONFIRM}              css=[data-testid="borrow-confirm"]
${BF_CONFIRM_OK}           css=[data-testid="borrow-confirm-ok"]
${BF_CONFIRM_CANCEL}       css=[data-testid="borrow-confirm-cancel"]
${BF_DRAFT_KEY}            borrow-form-draft

# ── /return ──
${RETURN_HEADER}           css=[data-testid="return-header"]
${RETURN_NEW}              css=[data-testid="return-new"]
${RETURN_STAT_TOTAL}       css=[data-testid="return-stat-total"]
${RETURN_STAT_COMPLETE}    css=[data-testid="return-stat-complete"]
${RETURN_STAT_DAMAGED}     css=[data-testid="return-stat-damaged"]
${RETURN_STAT_HANDED_OUT}  css=[data-testid="return-stat-handed-out"]
${RETURN_SECTION}          css=[data-testid="return-section"]
${TX_CONFIRM_RETURN}       css=[data-testid="tx-confirm-return"]
${TX_VIEW}                 css=[data-testid="tx-view"]
${RETURN_DETAIL}           css=[data-testid="return-detail"]
${RETURN_CONFIRM_MODAL}    css=[data-testid="return-confirm-modal"]
${RETURN_CONFIRM_OK}       css=[data-testid="return-confirm-modal-ok"]
${RETURN_CONFIRM_CANCEL}   css=[data-testid="return-confirm-modal-cancel"]

# ── /return/new ──
${RI_PAGE}                 css=[data-testid="return-intake-page"]
${RI_RETURNER_SEARCH}      css=[data-testid="return-returner-search"]
${RI_RETURNER_SUBMIT}      css=[data-testid="return-returner-submit"]
${RI_RETURNER_SELECTED}    css=[data-testid="return-returner-selected"]
${RI_RETURNER_CHANGE}      css=button[aria-label="เปลี่ยนผู้คืน"]
${RI_ASSET_CODE}           css=[data-testid="return-asset-code"]
${RI_ASSET_SCAN}           css=[data-testid="return-asset-scan"]
${RI_ASSET_FETCH}          css=[data-testid="return-asset-fetch"]
${RI_ASSET_ADD}            css=[data-testid="return-asset-add"]
${RI_ASSET_TABLE}          css=[data-testid="return-asset-table"]
${RI_ASSET_ROWS}           css=[data-testid="return-asset-row"]
${RI_NOTE}                 css=[data-testid="return-note"]
${RI_SUMMARY}              css=[data-testid="return-summary"]
${RI_STATUS}               css=[data-testid="return-status"]
${RI_CONFIRM}              css=[data-testid="return-confirm"]
${RI_DRAFT}                css=[data-testid="return-draft"]
${RI_CANCEL}               css=[data-testid="return-cancel"]
${RI_DRAFT_MODAL}          css=[data-testid="return-draft-modal"]
${RI_DRAFT_OK}             css=[data-testid="return-draft-modal-ok"]
${RI_CANCEL_MODAL}         css=[data-testid="return-cancel-modal"]
${RI_CANCEL_OK}            css=[data-testid="return-cancel-modal-ok"]
${RI_CANCEL_CANCEL}        css=[data-testid="return-cancel-modal-cancel"]
${RI_DRAFT_KEY}            return-intake-draft


*** Keywords ***
Transactions Page Should Be Loaded
    Wait For Elements State    ${TX_PAGE}    visible    timeout=20s
    Wait Until Keyword Succeeds    10x    1s    Transactions Table Should Have Rows

Transactions Table Should Have Rows
    ${rows}=    Get Element Count    ${TX_ROWS}
    Should Be True    ${rows} > 0    ตารางต้องมีรายการ

Search Transactions
    [Arguments]    ${text}
    Fill Text    ${TX_SEARCH}    ${text}
    Keyboard Key    press    Enter

Filter By Status
    [Arguments]    ${label}
    Click    ${TX_STATUS}
    Wait For Elements State    css=.ant-select-dropdown    visible    timeout=10s
    Click    css=.ant-select-item-option[title="${label}"]

# ───────────────────────── ทั่วไป ─────────────────────────
Choose Dropdown Option
    [Arguments]    ${select}    ${text}
    [Documentation]    เปิด antd Select แล้วเลือก option ที่มีข้อความ ${text} (เฉพาะ dropdown ที่เปิดอยู่)
    Click    ${select}
    ${option}=    Set Variable    ${OPEN_DROPDOWN} .ant-select-item-option:has-text("${text}")
    Wait For Elements State    ${option} >> nth=0    visible    timeout=10s
    Click    ${option} >> nth=0
    Wait For Elements State    ${OPEN_DROPDOWN}    hidden    timeout=5s

Stat Card Should Show Count
    [Arguments]    ${card}    ${label}
    [Documentation]    การ์ดสถิติต้องมีชื่อ และค่าเป็นตัวเลขตามด้วย "รายการ"
    Wait For Elements State    ${card}    visible    timeout=10s
    Get Text    ${card}    contains    ${label}
    Get Text    ${card} >> css=.stat-card__value    matches    ^[\\d,]+ รายการ$

Read Stat Count
    [Arguments]    ${card}
    [Documentation]    อ่านตัวเลขในการ์ดสถิติ เช่น "1,204 รายการ" → 1204
    ${text}=    Get Text    ${card} >> css=.stat-card__value
    ${number}=    Evaluate    int(re.sub(r'[^0-9]', '', $text.split()[0]))    modules=re
    RETURN    ${number}

Url Should Contain
    [Arguments]    ${fragment}
    [Documentation]    รอจน URL เปลี่ยนเป็น path ที่ต้องการ
    Wait Until Keyword Succeeds    20x    500ms    Get Url    contains    ${fragment}

Url Should End With
    [Arguments]    ${suffix}
    Wait Until Keyword Succeeds    20x    500ms    Get Url    matches    ${suffix}$

Clear Transaction Drafts
    [Documentation]    ลบฉบับร่างของฟอร์มยืม/คืนใน localStorage — ต้องอยู่บน origin ของแอปก่อน
    Evaluate JavaScript    ${None}
    ...    () => { localStorage.removeItem('${BF_DRAFT_KEY}'); localStorage.removeItem('${RI_DRAFT_KEY}') }

Read Draft
    [Arguments]    ${key}
    ${raw}=    Evaluate JavaScript    ${None}    (k) => localStorage.getItem(k)    arg=${key}
    RETURN    ${raw}

Draft Should Be Stored
    [Arguments]    ${key}
    ${raw}=    Read Draft    ${key}
    Should Not Be Equal    ${raw}    ${None}    ต้องมีฉบับร่าง ${key} ใน localStorage

Draft Should Be Cleared
    [Arguments]    ${key}
    ${raw}=    Read Draft    ${key}
    Should Be Equal    ${raw}    ${None}    ฉบับร่าง ${key} ต้องถูกลบ

Wait Until Page Visible
    [Arguments]    ${locator}    ${attempts}=3
    [Documentation]    รอ element หลักของหน้า — ถ้า dev server (Vite) ค้างจนหน้าขาว ให้ log error ของหน้าแล้ว reload ใหม่
    FOR    ${attempt}    IN RANGE    ${attempts}
        ${ok}=    Run Keyword And Return Status    Wait For Elements State    ${locator}    visible    timeout=15s
        IF    ${ok}    RETURN
        ${errors}=    Run Keyword And Ignore Error    Get Page Errors
        ${console}=    Run Keyword And Ignore Error    Get Console Log
        Log    หน้าไม่แสดงผลภายใน 15 วินาที (ครั้งที่ ${attempt + 1}) — reload ใหม่\nerrors: ${errors}\nconsole: ${console}    WARN
        Reload
    END
    Wait For Elements State    ${locator}    visible    timeout=15s

Reload Transactions Page
    [Documentation]    reload หน้า /borrow หรือ /return แล้วรอจนตารางมีข้อมูล
    Reload
    Wait Until Page Visible    ${TX_PAGE}
    Transactions Page Should Be Loaded
    Hide Dev Overlays

Hide Dev Overlays
    [Documentation]    ซ่อนปุ่ม TanStack Query Devtools (มุมขวาล่างตอนรัน dev) ที่บังปุ่มแบ่งหน้า — ต้องเรียกหลังโหลดหน้าทุกครั้ง
    Add Style Tag    .tsqd-parent-container { display: none !important; }

Close Open Modal
    [Documentation]    ปิด antd Modal ที่เปิดอยู่ด้วยปุ่ม X มุมขวาบน
    Click    ${ANT_MODAL_CLOSE}

Message Should Appear
    [Arguments]    ${text}
    [Documentation]    antd message (toast) ที่มีข้อความนี้ต้องขึ้นมา
    Wait For Elements State    ${TX_MESSAGE}:has-text("${text}") >> nth=0    visible    timeout=10s

Unique Stamp
    [Documentation]    เลขไม่ซ้ำ (ms) ใช้ตั้งชื่อ/รหัสข้อมูลทดสอบให้รันซ้ำได้
    ${stamp}=    Evaluate    str(int(time.time() * 1000))[-10:]    modules=time
    RETURN    ${stamp}

Row With Text
    [Arguments]    ${text}
    [Documentation]    locator ของแถวในตาราง tx-table ที่มีข้อความนี้
    RETURN    ${TX_ROWS}:has-text("${text}")

Search Until Row Appears
    [Arguments]    ${text}
    [Documentation]    ค้นหาแล้วรอจนแถวที่มีข้อความนี้แสดง (list refetch แบบ async)
    Search Transactions    ${text}
    ${row}=    Row With Text    ${text}
    Wait For Elements State    ${row}    visible    timeout=15s
    RETURN    ${row}

Every Visible Row Should Contain
    [Arguments]    ${text}
    ${rows}=    Get Element Count    ${TX_ROWS}
    Should Be True    ${rows} > 0    ต้องมีอย่างน้อย 1 แถว
    FOR    ${i}    IN RANGE    ${rows}
        Get Text    ${TX_ROWS} >> nth=${i}    contains    ${text}
    END

Every Visible Row Should Have Element
    [Arguments]    ${selector}
    [Documentation]    ทุกแถวในตารางต้องมี element นี้ (เช่น pill สถานะ)
    ${rows}=    Get Element Count    ${TX_ROWS}
    Should Be True    ${rows} > 0    ต้องมีอย่างน้อย 1 แถว
    ${hits}=    Get Element Count    ${TX_ROWS}:has(${selector})
    Should Be Equal As Integers    ${hits}    ${rows}

# ───────────────────────── API ช่วยเตรียมข้อมูล ─────────────────────────
Api Login
    [Arguments]    ${email}=${USER}    ${password}=${PASSWORD}
    [Documentation]    ล็อกอินผ่าน API แล้วคืน header Authorization
    ${body}=    Create Dictionary    email=${email}    password=${password}
    ${resp}=    POST    ${TX_API}/auth/login    json=${body}    expected_status=200
    ${headers}=    Create Dictionary    Authorization=Bearer ${resp.json()}[accessToken]
    RETURN    ${headers}

Api Create Equipment
    [Arguments]    ${auth}    ${code}    ${name}    ${quantity}=${10}    ${category}=${SEED_CATEGORY}
    [Documentation]    สร้างครุภัณฑ์เฉพาะของ test (รหัสไม่ซ้ำ) คืน JSON ของครุภัณฑ์
    ${body}=    Create Dictionary    code=${code}    name=${name}    category=${category}
    ...    quantity=${quantity}    price=${100}    department=ฝ่ายทดสอบ E2E
    ${resp}=    POST    ${TX_API}/equipment    json=${body}    headers=${auth}    expected_status=201
    RETURN    ${resp.json()}

Api Delete Equipment
    [Arguments]    ${auth}    ${id}
    DELETE    ${TX_API}/equipment/${id}    headers=${auth}    expected_status=any

Api Create Transaction
    [Arguments]    ${auth}    ${type}    ${equipment_id}    ${note}=${EMPTY}    ${quantity}=${1}
    [Documentation]    POST /transactions — borrow เริ่มที่ pending · return เริ่มที่ complete
    ...                รายการยืมใส่กำหนดคืน +7 วันเสมอ (หน้า /borrow แสดง "กำหนดคืน" และ suite borrow-return ตรวจข้อความนี้)
    ${body}=    Create Dictionary    type=${type}    equipmentId=${equipment_id}    quantity=${quantity}    note=${note}
    IF    '${type}' == 'borrow'
        ${due}=    Evaluate    (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=7)).isoformat()    modules=datetime
        Set To Dictionary    ${body}    dueAt=${due}
    END
    ${resp}=    POST    ${TX_API}/transactions    json=${body}    headers=${auth}    expected_status=201
    RETURN    ${resp.json()}

Api Set Transaction Status
    [Arguments]    ${auth}    ${id}    ${status}
    ${body}=    Create Dictionary    status=${status}
    PATCH    ${TX_API}/transactions/${id}/status    json=${body}    headers=${auth}    expected_status=200

Api Transaction Status Should Be
    [Arguments]    ${auth}    ${id}    ${status}
    ${resp}=    GET    ${TX_API}/transactions/${id}    headers=${auth}    expected_status=200
    Should Be Equal    ${resp.json()}[status]    ${status}

Api Find Transactions
    [Arguments]    ${auth}    ${type}    ${search}
    ${params}=    Create Dictionary    type=${type}    search=${search}    limit=${50}
    ${resp}=    GET    ${TX_API}/transactions    headers=${auth}    params=${params}    expected_status=200
    RETURN    ${resp.json()}[items]

Borrow Note
    [Arguments]    ${booker}    ${channel}=Walk-in    ${phone}=081-000-0000    ${department}=ฝ่ายทดสอบ E2E
    [Documentation]    สร้าง note แบบเดียวกับฟอร์มหน้า /borrow/new (buildBorrowNote)
    ${note}=    Catenate    SEPARATOR=\n
    ...    ผู้จอง: ${booker}    เบอร์โทร: ${phone}    หน่วยงาน: ${department}    ช่องทาง: ${channel}
    RETURN    ${note}

# ───────────────────────── /borrow/new ─────────────────────────
Open Borrow Form
    [Documentation]    เปิดฟอร์มจองใหม่แบบไม่มีฉบับร่างค้าง
    Go To    ${BASE_URL}/borrow/new
    Clear Transaction Drafts
    Reload
    Wait Until Page Visible    ${BF_PAGE}

Pick Borrow Equipment
    [Arguments]    ${code}
    [Documentation]    พิมพ์ค้นหาใน select ครุภัณฑ์ แล้วเลือกตัวที่มีรหัสนี้
    Click    ${BF_EQUIPMENT}
    Fill Text    ${BF_EQUIPMENT_INPUT}    ${code}
    ${option}=    Set Variable    ${OPEN_DROPDOWN} .ant-select-item-option:has-text("${code}")
    Wait For Elements State    ${option}    visible    timeout=15s
    Click    ${option}
    Wait For Elements State    ${OPEN_DROPDOWN}    hidden    timeout=5s
    Get Property    ${BF_EQUIPMENT_CODE}    value    ==    ${code}

Fill Borrow Pickup Date
    [Arguments]    ${date}
    [Documentation]    DatePicker รับค่าแบบพิมพ์ DD/MM/YYYY แล้วกด Enter
    Click    ${BF_DATE}
    Fill Text    ${BF_DATE}    ${date}
    Keyboard Key    press    Enter
    Get Property    ${BF_DATE}    value    ==    ${date}

Today Thai Format
    [Documentation]    วันนี้ในรูปแบบ DD/MM/YYYY (ค.ศ.) ตาม DatePicker
    ${today}=    Evaluate    datetime.date.today().strftime('%d/%m/%Y')    modules=datetime
    RETURN    ${today}

Borrow Submit Should Be Disabled
    Wait For Elements State    ${BF_SUBMIT}    disabled    timeout=5s

Borrow Submit Should Be Enabled
    Wait For Elements State    ${BF_SUBMIT}    enabled    timeout=10s

# ───────────────────────── /return/new ─────────────────────────
Open Return Intake
    [Documentation]    เปิดหน้ารับคืนแบบไม่มีฉบับร่างค้าง
    Go To    ${BASE_URL}/return/new
    Clear Transaction Drafts
    Reload
    Wait Until Page Visible    ${RI_PAGE}

Select Returner
    [Arguments]    ${name}
    [Documentation]    พิมพ์ชื่อผู้คืนแล้วกด "ค้นหา" → เลือกคนแรกที่ตรง
    Fill Text    ${RI_RETURNER_SEARCH}    ${name}
    Click    ${RI_RETURNER_SUBMIT}
    Wait For Elements State    ${RI_RETURNER_SELECTED}    visible    timeout=10s
    Get Text    ${RI_RETURNER_SELECTED}    contains    ${name}

Asset Row
    [Arguments]    ${code}
    RETURN    ${RI_ASSET_ROWS}:has-text("${code}")

Wait For Asset Row
    [Arguments]    ${code}
    ${row}=    Asset Row    ${code}
    Wait For Elements State    ${row}    visible    timeout=15s
    RETURN    ${row}

Asset Row Should Be Selected
    [Arguments]    ${code}
    ${row}=    Asset Row    ${code}
    Wait For Elements State    ${row} >> css=.ant-checkbox-input    checked    timeout=5s

Asset Row Should Not Be Selected
    [Arguments]    ${code}
    ${row}=    Asset Row    ${code}
    Wait For Elements State    ${row} >> css=.ant-checkbox-input    unchecked    timeout=5s

Toggle Asset Row
    [Arguments]    ${code}
    ${row}=    Asset Row    ${code}
    Click    ${row} >> css=.ant-checkbox-input

Untick All Asset Rows
    [Documentation]    เอาติ๊กออกทุกแถว (แถวที่ติ๊กอยู่ = ไม่มี class is-off)
    ${count}=    Get Element Count    ${RI_ASSET_ROWS}
    FOR    ${i}    IN RANGE    ${count}
        ${box}=    Set Variable    ${RI_ASSET_ROWS} >> nth=${i} >> css=.ant-checkbox-input
        ${checked}=    Get Checkbox State    ${box}
        IF    ${checked}    Click    ${box}
    END
    Get Element Count    css=[data-testid="return-asset-row"]:not(.is-off)    ==    0

Set Asset Condition
    [Arguments]    ${code}    ${label}
    ${row}=    Asset Row    ${code}
    Choose Dropdown Option    ${row} >> css=[data-testid="return-asset-condition"]    ${label}

Set Asset Reason
    [Arguments]    ${code}    ${label}
    ${row}=    Asset Row    ${code}
    Choose Dropdown Option    ${row} >> css=[data-testid="return-asset-reason"]    ${label}

Intake Status Should Be
    [Arguments]    ${text}
    Wait Until Keyword Succeeds    10x    500ms    Get Text    ${RI_STATUS}    ==    ${text}

Intake Selected Count Should Be
    [Arguments]    ${count}
    Wait Until Keyword Succeeds    10x    500ms
    ...    Get Text    ${RI_SUMMARY}    contains    จำนวนรายการทรัพย์สินที่รับคืน (${count} รายการ)
