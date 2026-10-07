*** Settings ***
Documentation     ทดสอบหน้า /return/new (รับคืนทรัพย์สิน) ทุก action — ค้นหาผู้คืน ตารางทรัพย์สินค้างคืน
...               ติ๊ก/เอาติ๊กออก สภาพ + เหตุผล ดึงข้อมูลจากรหัส สรุปการรับคืน ยืนยัน ฉบับร่าง และยกเลิก
...               ผู้คืนคือสมาชิก seed (${RETURNER}) — ยืมครุภัณฑ์รหัสไม่ซ้ำผ่าน API ในแต่ละ test
...               แล้วเอาติ๊กแถวอื่นของ seed ออกก่อนยืนยัน เพื่อไม่ให้กระทบข้อมูล seed
Resource          ../../resources/common.resource
Suite Setup       Prepare Intake Suite
Suite Teardown    Cleanup Intake Suite
Test Setup        Open Return Intake
Test Teardown     Clear Transaction Drafts
Test Tags         transactions    return-intake    ui


*** Variables ***
${RETURNER}           Koray Okumus
${RETURNER_EMAIL}     koray.okumus@example.com
@{EQUIPMENT_IDS}      @{EMPTY}
@{BORROW_IDS}         @{EMPTY}


*** Keywords ***
Prepare Intake Suite
    Open App    /login
    Start Fresh Session
    ${auth}=    Api Login
    Set Suite Variable    ${AUTH}    ${auth}
    ${member}=    Api Login    ${RETURNER_EMAIL}    ${PASSWORD}
    Set Suite Variable    ${MEMBER_AUTH}    ${member}

Cleanup Intake Suite
    [Documentation]    ปิดรายการยืมที่ test สร้างแต่ยังค้าง แล้วลบครุภัณฑ์ทดสอบ
    FOR    ${id}    IN    @{BORROW_IDS}
        Run Keyword And Ignore Error    Api Set Transaction Status    ${AUTH}    ${id}    complete
    END
    FOR    ${id}    IN    @{EQUIPMENT_IDS}
        Run Keyword And Ignore Error    Api Delete Equipment    ${AUTH}    ${id}
    END
    Close App

New Equipment
    [Arguments]    ${label}=ครุภัณฑ์รับคืน
    ${stamp}=    Unique Stamp
    ${equipment}=    Api Create Equipment    ${AUTH}    E2E-RI-${stamp}    ${label} ${stamp}    ${10}
    Append To List    ${EQUIPMENT_IDS}    ${equipment}[id]
    RETURN    ${equipment}

Create Open Borrow
    [Arguments]    ${status}=in_progress
    [Documentation]    ผู้คืนยืมครุภัณฑ์ใหม่ 1 ชิ้น (ผ่าน API ในชื่อสมาชิก) แล้วตั้งสถานะ — คืน JSON ของครุภัณฑ์
    ${equipment}=    New Equipment
    ${borrow}=    Api Create Transaction    ${MEMBER_AUTH}    borrow    ${equipment}[id]
    Append To List    ${BORROW_IDS}    ${borrow}[id]
    IF    '${status}' != 'pending'    Api Set Transaction Status    ${AUTH}    ${borrow}[id]    ${status}
    Set To Dictionary    ${equipment}    borrow_id=${borrow}[id]    borrow_code=${borrow}[code]
    RETURN    ${equipment}

Select Returner And Wait For
    [Arguments]    ${code}
    [Documentation]    reload ก่อน เพื่อให้ cache รายการครุภัณฑ์ (staleTime 5 นาที) รวมครุภัณฑ์ที่เพิ่งสร้างผ่าน API
    Reload
    Wait Until Page Visible    ${RI_PAGE}
    Select Returner    ${RETURNER}
    Wait For Asset Row    ${code}

Row Selects Should Be Disabled
    [Arguments]    ${code}
    ${row}=    Asset Row    ${code}
    Get Attribute    ${row} >> css=[data-testid="return-asset-condition"]    class    contains    ant-select-disabled
    Get Attribute    ${row} >> css=[data-testid="return-asset-reason"]    class    contains    ant-select-disabled

Summary Remark Should Be
    [Arguments]    ${text}
    Wait Until Keyword Succeeds    10x    500ms
    ...    Get Text    ${RI_SUMMARY} >> css=dl > div:nth-child(2) dd    ==    ${text}

Confirm Button Should Be Disabled
    Wait For Elements State    ${RI_CONFIRM}    disabled    timeout=5s

Confirm Button Should Be Enabled
    Wait For Elements State    ${RI_CONFIRM}    enabled    timeout=5s

Only Row Should Be Ready
    [Arguments]    ${code}    ${reason}=ครบกำหนดยืม
    [Documentation]    เอาติ๊กออกทุกแถว ติ๊กเฉพาะแถวนี้ แล้วเลือกเหตุผล
    Untick All Asset Rows
    Toggle Asset Row    ${code}
    Asset Row Should Be Selected    ${code}
    Set Asset Reason    ${code}    ${reason}


*** Test Cases ***
Intake Starts With Confirm Disabled
    [Documentation]    เปิดหน้าใหม่: ยังไม่เลือกผู้คืน · ตารางว่าง · สถานะ "รอระบุผู้คืน" · ปุ่มยืนยันกดไม่ได้
    [Tags]    smoke
    Get Text    ${RI_PAGE}    contains    ขั้นตอนรับคืนของใช้และทรัพย์สินออฟฟิศ
    Get Text    ${RI_ASSET_TABLE}    contains    เลือกผู้คืนเพื่อดึงรายการทรัพย์สิน
    Get Element Count    ${RI_ASSET_ROWS}    ==    0
    Intake Status Should Be    รอระบุผู้คืน
    Intake Selected Count Should Be    0
    Confirm Button Should Be Disabled
    Capture Page    90-intake-empty

Unknown Returner Shows Warning
    [Documentation]    ค้นหาชื่อที่ไม่มี → แจ้งเตือน "ไม่พบผู้ใช้งานที่ค้นหา" และยังไม่เลือกผู้คืน
    Fill Text    ${RI_RETURNER_SEARCH}    ไม่มีผู้ใช้คนนี้-xyz
    Click    ${RI_RETURNER_SUBMIT}
    Message Should Appear    ไม่พบผู้ใช้งานที่ค้นหา
    Get Element Count    ${RI_RETURNER_SELECTED}    ==    0
    Intake Status Should Be    รอระบุผู้คืน

Selecting Returner Loads Open Borrows
    [Documentation]    เลือกผู้คืน → แสดงชื่อ/อีเมล · ตารางดึงรายการยืมที่ยังไม่คืน (อนุมัติแล้ว/กำลังยืม)
    ...                ไม่รวมรายการที่ยังรออนุมัติ · ทุกแถวติ๊กไว้ก่อนและสถานะ "รอตรวจสภาพ" · ปุ่มเปลี่ยนผู้คืนล้างค่า
    ${open}=    Create Open Borrow    in_progress
    ${approved}=    Create Open Borrow    approved
    ${pending}=    Create Open Borrow    pending
    Select Returner And Wait For    ${open}[code]
    Get Text    ${RI_RETURNER_SELECTED}    contains    ${RETURNER_EMAIL}
    Wait For Asset Row    ${approved}[code]
    ${row}=    Asset Row    ${open}[code]
    Get Text    ${row}    contains    ${open}[name]
    Get Text    ${row}    contains    รหัสทรัพย์สิน: ${open}[code]
    Get Text    ${row}    contains    ประเภท: ${SEED_CATEGORY}
    Get Text    ${row}    contains    ผู้รับผิดชอบ: ฝ่ายทดสอบ E2E
    ${pending_row}=    Asset Row    ${pending}[code]
    Get Element Count    ${pending_row}    ==    0
    Get Element Count    css=[data-testid="return-asset-row"].is-off    ==    0
    Asset Row Should Be Selected    ${open}[code]
    Intake Status Should Be    รอตรวจสภาพ
    Confirm Button Should Be Disabled
    Capture Page    91-intake-returner-loaded
    Click    ${RI_RETURNER_CHANGE}
    Wait For Elements State    ${RI_RETURNER_SELECTED}    detached    timeout=10s
    Get Property    ${RI_RETURNER_SEARCH}    value    ==    ${EMPTY}
    Intake Status Should Be    รอระบุผู้คืน

Tick Rows And Set Condition And Reason
    [Documentation]    เอาติ๊กออกทั้งหมด → "ยังไม่เลือกทรัพย์สิน" · ติ๊กแถวเดียว → สรุป 1 รายการ
    ...                เปลี่ยนสภาพ → หมายเหตุการตรวจสภาพ · เลือกเหตุผล → "พร้อมส่งคืนคลัง" และปุ่มยืนยันกดได้
    ${eq}=    Create Open Borrow
    Select Returner And Wait For    ${eq}[code]
    Untick All Asset Rows
    Intake Status Should Be    ยังไม่เลือกทรัพย์สิน
    Intake Selected Count Should Be    0
    Row Selects Should Be Disabled    ${eq}[code]
    Confirm Button Should Be Disabled
    Toggle Asset Row    ${eq}[code]
    Asset Row Should Be Selected    ${eq}[code]
    Intake Selected Count Should Be    1
    Intake Status Should Be    รอตรวจสภาพ
    Summary Remark Should Be    ไม่มี
    Get Text    ${RI_SUMMARY}    contains    รอตรวจสอบ
    Set Asset Condition    ${eq}[code]    มีรอยขีดข่วน
    ${row}=    Asset Row    ${eq}[code]
    Get Text    ${row} >> css=[data-testid="return-asset-condition"]    contains    มีรอยขีดข่วน
    Summary Remark Should Be    มี 1 รายการมีรอยขีดข่วน
    Confirm Button Should Be Disabled
    Set Asset Reason    ${eq}[code]    ครบกำหนดยืม
    Get Text    ${row} >> css=[data-testid="return-asset-reason"]    contains    ครบกำหนดยืม
    Intake Status Should Be    พร้อมส่งคืนคลัง
    Get Text    ${RI_SUMMARY}    contains    ตรวจสอบแล้ว
    Confirm Button Should Be Enabled
    Capture Page    92-intake-ready
    # เอาติ๊กออกอีกครั้ง → กลับไปยังไม่พร้อม
    Toggle Asset Row    ${eq}[code]
    Asset Row Should Not Be Selected    ${eq}[code]
    Get Attribute    ${row}    class    contains    is-off
    Intake Status Should Be    ยังไม่เลือกทรัพย์สิน
    Confirm Button Should Be Disabled

Asset Code Fetch Selects Or Adds Rows
    [Documentation]    ดึงข้อมูลทรัพย์สิน: ช่องว่าง → แจ้งให้กรอก · รหัสที่อยู่ในรายการยืม → ติ๊กแถวนั้น
    ...                · รหัสนอกรายการ → เพิ่มแถว "เพิ่มนอกรายการยืม" · รหัสไม่มีในระบบ → เตือน
    ...                · ปุ่มสแกน QR และลิงก์เพิ่มทรัพย์สินแสดงคำแนะนำ
    ${eq}=    Create Open Borrow
    ${extra}=    New Equipment    ครุภัณฑ์นอกรายการ
    Select Returner And Wait For    ${eq}[code]
    Click    ${RI_ASSET_FETCH}
    Message Should Appear    กรอกรหัสทรัพย์สินก่อน
    Untick All Asset Rows
    Fill Text    ${RI_ASSET_CODE}    ${eq}[code]
    Click    ${RI_ASSET_FETCH}
    Message Should Appear    เลือก ${eq}[name] แล้ว
    Asset Row Should Be Selected    ${eq}[code]
    Get Property    ${RI_ASSET_CODE}    value    ==    ${EMPTY}
    Intake Selected Count Should Be    1
    Fill Text    ${RI_ASSET_CODE}    ${extra}[code]
    Keyboard Key    press    Enter
    Message Should Appear    เพิ่ม ${extra}[name] แล้ว
    ${extra_row}=    Wait For Asset Row    ${extra}[code]
    Get Text    ${extra_row}    contains    เพิ่มนอกรายการยืม
    Asset Row Should Be Selected    ${extra}[code]
    Intake Selected Count Should Be    2
    Fill Text    ${RI_ASSET_CODE}    NO-SUCH-ASSET-${eq}[code]
    Click    ${RI_ASSET_FETCH}
    Message Should Appear    ไม่พบทรัพย์สินจากรหัสนี้
    Intake Selected Count Should Be    2
    Click    ${RI_ASSET_SCAN}
    Message Should Appear    ยังไม่รองรับการสแกนจากกล้อง
    Click    ${RI_ASSET_ADD}
    Message Should Appear    กรอกรหัสทรัพย์สินที่ต้องการเพิ่ม
    Capture Page    93-intake-asset-fetch

Confirm Return Creates Return Transactions
    [Documentation]    ติ๊ก 2 แถว (ปกติ + ชำรุด) ใส่เหตุผลและบันทึก → ยืนยัน → modal (ลองยกเลิกก่อน) → ยืนยัน
    ...                → กลับ /return · ปกติ = "คืนสำเร็จแล้ว" · ชำรุด = "รอเจ้าหน้าที่ตรวจ" · รายการยืมเดิมปิดเป็น complete
    [Tags]    smoke
    ${good}=    Create Open Borrow
    ${broken}=    Create Open Borrow    approved
    Select Returner And Wait For    ${good}[code]
    Wait For Asset Row    ${broken}[code]
    Untick All Asset Rows
    Toggle Asset Row    ${good}[code]
    Toggle Asset Row    ${broken}[code]
    Set Asset Reason    ${good}[code]    ครบกำหนดยืม
    Set Asset Condition    ${broken}[code]    ชำรุด / เสียหาย
    Set Asset Reason    ${broken}[code]    เสร็จสิ้นโครงการ
    Fill Text    ${RI_NOTE}    ตรวจรับโดย E2E
    Intake Selected Count Should Be    2
    Summary Remark Should Be    มี 1 รายการชำรุด / เสียหาย
    Intake Status Should Be    พร้อมส่งคืนคลัง
    Click    ${RI_CONFIRM}
    Wait For Elements State    ${RETURN_CONFIRM_MODAL}    visible    timeout=10s
    Click    ${RETURN_CONFIRM_CANCEL}
    Wait For Elements State    ${RETURN_CONFIRM_MODAL}    detached    timeout=10s
    Get Url    contains    /return/new
    Click    ${RI_CONFIRM}
    Wait For Elements State    ${RETURN_CONFIRM_MODAL}    visible    timeout=10s
    Get Text    ${RETURN_CONFIRM_MODAL}    contains    ต้องการยืนยันรับคืน ?
    Capture Page    94-intake-confirm-modal
    Click    ${RETURN_CONFIRM_OK}
    Message Should Appear    รับคืนแล้ว 2 รายการ
    Url Should End With    /return
    Transactions Page Should Be Loaded
    Hide Dev Overlays
    Search Transactions    ${good}[code]
    ${row}=    Row With Text    ${good}[name]
    Wait For Elements State    ${row}    visible    timeout=15s
    Get Text    ${row}    contains    ${RETURNER}
    Get Text    ${row}    contains    ปกติ (สมบูรณ์)
    Get Text    ${row} >> css=[data-testid="status-complete"]    ==    คืนสำเร็จแล้ว
    Capture Page    95-intake-returned
    Search Transactions    ${broken}[code]
    ${row}=    Row With Text    ${broken}[name]
    Wait For Elements State    ${row}    visible    timeout=15s
    Get Text    ${row}    contains    ชำรุด / เสียหาย
    Get Text    ${row} >> css=[data-testid="status-in_progress"]    ==    รอเจ้าหน้าที่ตรวจ
    Api Transaction Status Should Be    ${AUTH}    ${good}[borrow_id]    complete
    Api Transaction Status Should Be    ${AUTH}    ${broken}[borrow_id]    complete
    ${returns}=    Api Find Transactions    ${AUTH}    return    ${good}[code]
    Length Should Be    ${returns}    1
    Should Contain    ${returns}[0][note]    ผู้คืน: ${RETURNER}
    Should Contain    ${returns}[0][note]    อ้างอิง: ${good}[borrow_code]
    Should Contain    ${returns}[0][note]    หมายเหตุ: ตรวจรับโดย E2E
    Draft Should Be Cleared    ${RI_DRAFT_KEY}

Save Draft And Restore After Reload
    [Documentation]    บันทึกฉบับร่าง → modal → ยืนยัน → reload → ผู้คืน ติ๊ก สภาพ เหตุผล และบันทึกกลับมาครบ
    ${eq}=    Create Open Borrow
    Select Returner And Wait For    ${eq}[code]
    Only Row Should Be Ready    ${eq}[code]    ย้ายทีมงาน
    Set Asset Condition    ${eq}[code]    มีรอยขีดข่วน
    Fill Text    ${RI_NOTE}    บันทึกฉบับร่าง E2E
    Click    ${RI_DRAFT}
    Wait For Elements State    ${RI_DRAFT_MODAL}    visible    timeout=10s
    Get Text    ${RI_DRAFT_MODAL}    contains    ต้องการบันทึกเป็นฉบับร่างใช่ไหม?
    Capture Page    96-intake-draft-modal
    Click    ${RI_DRAFT_OK}
    Wait For Elements State    ${RI_DRAFT_MODAL}    detached    timeout=10s
    Message Should Appear    บันทึกฉบับร่างแล้ว
    Draft Should Be Stored    ${RI_DRAFT_KEY}
    Reload
    Wait Until Page Visible    ${RI_PAGE}
    Wait For Elements State    ${RI_RETURNER_SELECTED}    visible    timeout=10s
    Get Text    ${RI_RETURNER_SELECTED}    contains    ${RETURNER}
    ${row}=    Wait For Asset Row    ${eq}[code]
    Asset Row Should Be Selected    ${eq}[code]
    Get Text    ${row} >> css=[data-testid="return-asset-condition"]    contains    มีรอยขีดข่วน
    Get Text    ${row} >> css=[data-testid="return-asset-reason"]    contains    ย้ายทีมงาน
    Get Property    ${RI_NOTE}    value    ==    บันทึกฉบับร่าง E2E
    Intake Selected Count Should Be    1
    Intake Status Should Be    พร้อมส่งคืนคลัง
    Confirm Button Should Be Enabled
    Capture Page    97-intake-draft-restored

Cancel Asks Before Discarding And Clears Draft
    [Documentation]    ยกเลิก → modal สีแดง · "ยกเลิก" ใน modal = อยู่ต่อ · "ลบ" → กลับ /return และลบฉบับร่าง
    ${eq}=    Create Open Borrow
    Select Returner And Wait For    ${eq}[code]
    Click    ${RI_DRAFT}
    Click    ${RI_DRAFT_OK}
    Wait For Elements State    ${RI_DRAFT_MODAL}    detached    timeout=10s
    Draft Should Be Stored    ${RI_DRAFT_KEY}
    Click    ${RI_CANCEL}
    Wait For Elements State    ${RI_CANCEL_MODAL}    visible    timeout=10s
    Get Text    ${RI_CANCEL_MODAL}    contains    ต้องการยกเลิกการยืมคืน ?
    Get Text    ${RI_CANCEL_OK}    ==    ลบ
    Click    ${RI_CANCEL_CANCEL}
    Wait For Elements State    ${RI_CANCEL_MODAL}    detached    timeout=10s
    Get Url    contains    /return/new
    Wait For Elements State    ${RI_RETURNER_SELECTED}    visible
    Click    ${RI_CANCEL}
    Wait For Elements State    ${RI_CANCEL_MODAL}    visible    timeout=10s
    Capture Page    98-intake-cancel-modal
    Click    ${RI_CANCEL_OK}
    Url Should End With    /return
    Transactions Page Should Be Loaded
    Draft Should Be Cleared    ${RI_DRAFT_KEY}
    Go To    ${BASE_URL}/return/new
    Wait Until Page Visible    ${RI_PAGE}
    Get Element Count    ${RI_RETURNER_SELECTED}    ==    0
    Intake Status Should Be    รอระบุผู้คืน
    Api Transaction Status Should Be    ${AUTH}    ${eq}[borrow_id]    in_progress
