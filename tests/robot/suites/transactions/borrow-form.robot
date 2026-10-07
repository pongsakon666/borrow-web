*** Settings ***
Documentation     ทดสอบฟอร์ม /borrow/new ทุก action — validate ปุ่มบันทึก ย้อนกลับ กรอกครบแล้วบันทึกจริง
...               ปุ่มเพิ่ม/ลดจำนวน แถบจัดรูปแบบ ฉบับร่าง (บันทึก/โหลดคืน) ยกเลิก และ popup สแกน QR
...               ครุภัณฑ์ที่ใช้สร้างผ่าน API (รหัสไม่ซ้ำ) และล้าง localStorage ก่อนทุก test
Resource          ../../resources/common.resource
Suite Setup       Prepare Borrow Form Suite
Suite Teardown    Cleanup Borrow Form Suite
Test Setup        Open Borrow Form
Test Teardown     Clear Transaction Drafts
Test Tags         transactions    borrow-form    ui


*** Variables ***
${EQUIPMENT}      ${None}
${SMALL}          ${None}
${WALKIN_LABEL}   Walk-in (ติดต่อหน้าเคาน์เตอร์)
${COLOR}          สีขาว (White)


*** Keywords ***
Prepare Borrow Form Suite
    Open App    /login
    Start Fresh Session
    ${auth}=    Api Login
    Set Suite Variable    ${AUTH}    ${auth}
    ${stamp}=    Unique Stamp
    Set Suite Variable    ${STAMP}    ${stamp}
    ${equipment}=    Api Create Equipment    ${AUTH}    E2E-BF-${stamp}    ครุภัณฑ์ทดสอบฟอร์มจอง ${stamp}    ${20}
    Set Suite Variable    ${EQUIPMENT}    ${equipment}
    ${small}=    Api Create Equipment    ${AUTH}    E2E-BFS-${stamp}    ครุภัณฑ์จำนวนน้อย ${stamp}    ${2}
    Set Suite Variable    ${SMALL}    ${small}

Cleanup Borrow Form Suite
    [Documentation]    ปิดรายการจองที่ test สร้าง แล้วลบครุภัณฑ์ทดสอบ
    IF    $EQUIPMENT
        ${items}=    Api Find Transactions    ${AUTH}    borrow    ${EQUIPMENT}[code]
        FOR    ${item}    IN    @{items}
            Run Keyword And Ignore Error    Api Set Transaction Status    ${AUTH}    ${item}[id]    complete
        END
        Run Keyword And Ignore Error    Api Delete Equipment    ${AUTH}    ${EQUIPMENT}[id]
    END
    IF    $SMALL    Run Keyword And Ignore Error    Api Delete Equipment    ${AUTH}    ${SMALL}[id]
    Close App

Fill Required Fields
    [Arguments]    ${booker}    ${code}=${EQUIPMENT}[code]
    [Documentation]    กรอกเฉพาะฟิลด์บังคับ: ผู้จอง วันที่รับ ช่องทาง ครุภัณฑ์
    Fill Text    ${BF_BOOKER}    ${booker}
    ${today}=    Today Thai Format
    Fill Borrow Pickup Date    ${today}
    Choose Dropdown Option    ${BF_CHANNEL}    ${WALKIN_LABEL}
    Pick Borrow Equipment    ${code}

Quantity Should Be
    [Arguments]    ${value}
    Get Property    ${BF_QUANTITY}    value    ==    ${value}
    Get Text    ${BF_QTY_DISPLAY}    ==    ${value}

Open Confirm Modal
    [Arguments]    ${button}    ${title}
    Click    ${button}
    Wait For Elements State    ${BF_CONFIRM}    visible    timeout=10s
    Get Text    ${BF_CONFIRM}    contains    ${title}

Confirm Modal Should Close
    Wait For Elements State    ${BF_CONFIRM}    detached    timeout=10s


*** Test Cases ***
Form Renders With Save Disabled
    [Documentation]    เปิดหน้าใหม่: หัวข้อ ส่วน 1-5 ครบ · ปุ่ม "บันทึกรายการจอง" disabled · จำนวนเริ่มที่ 1
    [Tags]    smoke
    Get Text    ${BF_PAGE}    contains    บันทึกรายการจองใหม่ (เพิ่มรายการ)
    FOR    ${section}    IN    1. ข้อมูลผู้จองครุภัณฑ์    2. ข้อมูลวันเวลาและประเภทการจอง
    ...    3. รายการครุภัณฑ์ที่ต้องการจอง    4. หมายเหตุเพิ่มเติม    5. สรุปบันทึกการทำงาน (Log)
        Get Text    ${BF_PAGE}    contains    ${section}
    END
    Get Text    css=[data-testid="borrow-summary"]    contains    ${USER_NAME}
    Borrow Submit Should Be Disabled
    Quantity Should Be    1
    Capture Page    70-borrow-form-empty

Save Stays Disabled Until All Required Fields Are Valid
    [Documentation]    กรอกทีละฟิลด์บังคับ ปุ่มยัง disabled จนครบ · ลบชื่อผู้จอง → disabled อีกครั้ง
    Fill Text    ${BF_BOOKER}    ผู้จองทดสอบ ${STAMP}
    Borrow Submit Should Be Disabled
    ${today}=    Today Thai Format
    Fill Borrow Pickup Date    ${today}
    Borrow Submit Should Be Disabled
    Choose Dropdown Option    ${BF_CHANNEL}    ${WALKIN_LABEL}
    Borrow Submit Should Be Disabled
    Pick Borrow Equipment    ${EQUIPMENT}[code]
    Borrow Submit Should Be Enabled
    Fill Text    ${BF_BOOKER}    ${EMPTY}
    Borrow Submit Should Be Disabled
    Fill Text    ${BF_BOOKER}    ${SPACE}${SPACE}
    Borrow Submit Should Be Disabled

Back Button Returns To Borrow List
    [Documentation]    ปุ่ม "ย้อนกลับ" → /borrow
    Get Text    ${BF_BACK}    ==    ย้อนกลับ
    Click    ${BF_BACK}
    Url Should End With    /borrow
    Transactions Page Should Be Loaded

Fill Whole Form And Save Booking
    [Documentation]    กรอกทุกฟิลด์ (Walk-in) → บันทึกรายการจอง → modal (ลองยกเลิกก่อน) → ยืนยัน
    ...                → กลับ /borrow · ค้นหาเจอในตาราง Walk-in และ note ใน API เก็บครบ
    [Tags]    smoke
    ${booker}=    Set Variable    ผู้จองฟอร์ม ${STAMP}
    Fill Text    ${BF_BOOKER}    ${booker}
    Fill Text    ${BF_PHONE}    089-123-4567
    Fill Text    ${BF_DEPARTMENT}    ฝ่ายเทคโนโลยีสารสนเทศ
    ${today}=    Today Thai Format
    Fill Borrow Pickup Date    ${today}
    Choose Dropdown Option    ${BF_CHANNEL}    ${WALKIN_LABEL}
    Get Text    ${BF_CHANNEL}    contains    ${WALKIN_LABEL}
    Pick Borrow Equipment    ${EQUIPMENT}[code]
    Get Property    ${BF_EQUIPMENT_NAME}    value    ==    ${EQUIPMENT}[name]
    # เลือกครุภัณฑ์แล้วหมวดหมู่หลักถูกเติมให้อัตโนมัติ
    Get Text    ${BF_CATEGORY}    contains    ${SEED_CATEGORY}
    Get Text    css=.borrow-form__layout    matches    คงเหลือพร้อมยืม \\d+ ชิ้น
    Click    ${BF_QTY_PLUS}
    Click    ${BF_QTY_PLUS}
    Quantity Should Be    3
    Click    ${BF_QTY_MINUS}
    Quantity Should Be    2
    Choose Dropdown Option    ${BF_COLOR}    ${COLOR}
    Get Text    ${BF_COLOR}    contains    ${COLOR}
    Choose Dropdown Option    ${BF_CATEGORY}    ${SEED_CATEGORY}
    Fill Text    ${BF_SUBCATEGORY}    หมวดย่อยทดสอบ
    Keyboard Key    press    Escape
    Fill Text    ${BF_DETAILS}    สภาพสมบูรณ์ ครบกล่อง
    Fill Text    ${BF_REMARK}    รับแทนโดยเจ้าหน้าที่ E2E
    Borrow Submit Should Be Enabled
    Capture Page    71-borrow-form-filled
    # ยกเลิกใน modal → ยังอยู่หน้าฟอร์ม ค่าไม่หาย
    Open Confirm Modal    ${BF_SUBMIT}    ยืนยันการบันทึกข้อมูล ?
    Click    ${BF_CONFIRM_CANCEL}
    Confirm Modal Should Close
    Get Property    ${BF_PHONE}    value    ==    089-123-4567
    Open Confirm Modal    ${BF_SUBMIT}    ยืนยันการบันทึกข้อมูล ?
    Capture Page    72-borrow-form-confirm
    Click    ${BF_CONFIRM_OK}
    Message Should Appear    บันทึกรายการจองแล้ว
    Url Should End With    /borrow
    Transactions Page Should Be Loaded
    Hide Dev Overlays
    # ค้นหาด้วยรหัสครุภัณฑ์ (API ค้นหาจาก userName/อุปกรณ์/รหัส — ชื่อผู้จองอยู่ใน note)
    Search Transactions    ${EQUIPMENT}[code]
    ${row}=    Row With Text    ${booker}
    Wait For Elements State    ${row}    visible    timeout=15s
    Get Text    ${row}    contains    ${EQUIPMENT}[name]
    Get Text    ${row}    contains    2 ชิ้น
    Get Text    ${row}    contains    ฝ่ายเทคโนโลยีสารสนเทศ
    Get Text    ${BORROW_SECTION_WALKIN}    contains    ${booker}
    Get Text    ${BORROW_SECTION_BOOKING}    not contains    ${booker}
    Capture Page    73-borrow-form-saved
    ${items}=    Api Find Transactions    ${AUTH}    borrow    ${EQUIPMENT}[code]
    ${tx}=    Evaluate    next(filter(lambda item, name=$booker: name in item['note'], $items))
    Should Be Equal As Integers    ${tx}[quantity]    2
    Should Be Equal    ${tx}[status]    pending
    FOR    ${line}    IN    ผู้จอง: ${booker}    เบอร์โทร: 089-123-4567    หน่วยงาน: ฝ่ายเทคโนโลยีสารสนเทศ
    ...    วันที่รับ: ${today}    ช่องทาง: Walk-in    สี: ${COLOR}    หมวดหมู่หลัก: ${SEED_CATEGORY}
    ...    หมวดหมู่ย่อย: หมวดย่อยทดสอบ    รายละเอียด: สภาพสมบูรณ์ ครบกล่อง    หมายเหตุ: รับแทนโดยเจ้าหน้าที่ E2E
        Should Contain    ${tx}[note]    ${line}
    END
    Draft Should Be Cleared    ${BF_DRAFT_KEY}

Quantity Stepper Respects Minimum And Available Stock
    [Documentation]    ปุ่ม − ไม่ต่ำกว่า 1 · ปุ่ม + ไม่เกินจำนวนคงเหลือของครุภัณฑ์ (มี 2 ชิ้น)
    Click    ${BF_QTY_MINUS}
    Quantity Should Be    1
    Pick Borrow Equipment    ${SMALL}[code]
    # อ่านจำนวนคงเหลือจากข้อความใต้ช่อง (ครุภัณฑ์มี 2 ชิ้น — suite อื่นอาจยืมไปบ้าง)
    ${hint}=    Get Text    css=.ant-form-item-extra:has-text("คงเหลือพร้อมยืม")
    ${available}=    Evaluate    int(re.search(r'คงเหลือพร้อมยืม (\\d+)', $hint).group(1))    modules=re
    Should Be True    1 <= ${available} <= 2
    FOR    ${i}    IN RANGE    ${available} + 1
        Click    ${BF_QTY_PLUS}
    END
    Quantity Should Be    ${{ str($available) }}
    Click    ${BF_QTY_MINUS}
    Click    ${BF_QTY_MINUS}
    Click    ${BF_QTY_MINUS}
    Quantity Should Be    1

Details Toolbar Formats Text
    [Documentation]    แถบเครื่องมือของรายละเอียด: ตัวหนา / ตัวเอียง / ขีดเส้นใต้ / ลิงก์ / รายการ / หัวข้อ
    Fill Text    ${BF_DETAILS}    abc
    Click    css=button[aria-label="ตัวหนา"]
    Get Property    ${BF_DETAILS}    value    ==    abc****
    Fill Text    ${BF_DETAILS}    abc
    Click    css=button[aria-label="ตัวเอียง"]
    Get Property    ${BF_DETAILS}    value    ==    abc__
    Fill Text    ${BF_DETAILS}    abc
    Click    css=button[aria-label="ขีดเส้นใต้"]
    Get Property    ${BF_DETAILS}    value    ==    abc____
    Fill Text    ${BF_DETAILS}    abc
    Click    css=button[aria-label="ลิงก์"]
    Get Property    ${BF_DETAILS}    value    ==    abc[](https://)
    Fill Text    ${BF_DETAILS}    abc
    Click    css=button[aria-label="รายการ"]
    Get Property    ${BF_DETAILS}    value    ==    abc\n-${SPACE}
    Fill Text    ${BF_DETAILS}    abc
    Choose Dropdown Option    css=.borrow-editor__style    หัวข้อ (Heading)
    Get Property    ${BF_DETAILS}    value    ==    abc#${SPACE}

Save Draft And Restore After Reload
    [Documentation]    บันทึกฉบับร่าง → modal → ยืนยัน → reload หน้า → ค่าที่กรอกกลับมาครบ และบันทึกได้ทันที
    ${booker}=    Set Variable    ผู้จองฉบับร่าง ${STAMP}
    Fill Required Fields    ${booker}
    Fill Text    ${BF_PHONE}    02-555-0000
    Fill Text    ${BF_DEPARTMENT}    ฝ่ายร่าง
    Click    ${BF_QTY_PLUS}
    Choose Dropdown Option    ${BF_COLOR}    ${COLOR}
    Fill Text    ${BF_REMARK}    หมายเหตุฉบับร่าง
    Open Confirm Modal    ${BF_DRAFT}    ต้องการบันทึกเป็นฉบับร่างใช่ไหม?
    Capture Page    74-borrow-draft-modal
    Click    ${BF_CONFIRM_OK}
    Confirm Modal Should Close
    Message Should Appear    บันทึกฉบับร่างแล้ว
    Draft Should Be Stored    ${BF_DRAFT_KEY}
    Reload
    Wait Until Page Visible    ${BF_PAGE}
    Get Property    ${BF_BOOKER}    value    ==    ${booker}
    Get Property    ${BF_PHONE}    value    ==    02-555-0000
    Get Property    ${BF_DEPARTMENT}    value    ==    ฝ่ายร่าง
    ${today}=    Today Thai Format
    Get Property    ${BF_DATE}    value    ==    ${today}
    Get Text    ${BF_CHANNEL}    contains    ${WALKIN_LABEL}
    Get Property    ${BF_EQUIPMENT_NAME}    value    ==    ${EQUIPMENT}[name]
    Get Property    ${BF_EQUIPMENT_CODE}    value    ==    ${EQUIPMENT}[code]
    Quantity Should Be    2
    Get Text    ${BF_COLOR}    contains    ${COLOR}
    Get Property    ${BF_REMARK}    value    ==    หมายเหตุฉบับร่าง
    Borrow Submit Should Be Enabled
    Capture Page    75-borrow-draft-restored

Cancel Asks Before Discarding And Clears Draft
    [Documentation]    ยกเลิก → modal สีแดง · กด "ยกเลิก" ใน modal = อยู่ต่อ · กด "ลบ" → กลับ /borrow และฉบับร่างถูกลบ
    Fill Text    ${BF_BOOKER}    ผู้จองที่จะยกเลิก ${STAMP}
    Open Confirm Modal    ${BF_DRAFT}    ต้องการบันทึกเป็นฉบับร่างใช่ไหม?
    Click    ${BF_CONFIRM_OK}
    Confirm Modal Should Close
    Draft Should Be Stored    ${BF_DRAFT_KEY}
    Open Confirm Modal    ${BF_CANCEL}    ต้องการยกเลิกรายการบันทึก?
    Get Text    ${BF_CONFIRM_OK}    ==    ลบ
    Click    ${BF_CONFIRM_CANCEL}
    Confirm Modal Should Close
    Get Url    contains    /borrow/new
    Draft Should Be Stored    ${BF_DRAFT_KEY}
    Open Confirm Modal    ${BF_CANCEL}    ต้องการยกเลิกรายการบันทึก?
    Capture Page    76-borrow-cancel-modal
    Click    ${BF_CONFIRM_OK}
    Url Should End With    /borrow
    Transactions Page Should Be Loaded
    Draft Should Be Cleared    ${BF_DRAFT_KEY}
    # เปิดฟอร์มใหม่ต้องว่าง
    Go To    ${BASE_URL}/borrow/new
    Wait Until Page Visible    ${BF_PAGE}
    Get Property    ${BF_BOOKER}    value    ==    ${EMPTY}

Scan Popup Selects Equipment By Code
    [Documentation]    ปุ่ม "สแกน QR / บาร์โค้ด" เปิด popup · รหัสไม่มีในระบบ → เตือนและ popup ยังเปิด
    ...                · ปุ่มยกเลิกปิด popup · พิมพ์รหัสแล้ว Enter/ค้นหา → เลือกครุภัณฑ์ (ชื่อ+รหัส) ให้อัตโนมัติ
    Click    ${BF_SCAN}
    Wait For Elements State    ${BF_SCAN_INPUT}    visible    timeout=10s
    Get Text    css=.ant-modal-title >> text=สแกน QR / บาร์โค้ด    ==    สแกน QR / บาร์โค้ด
    Fill Text    ${BF_SCAN_INPUT}    NO-SUCH-CODE-${STAMP}
    Keyboard Key    press    Enter
    Message Should Appear    ไม่พบครุภัณฑ์จากรหัสนี้
    Wait For Elements State    ${BF_SCAN_INPUT}    visible
    Click    css=.ant-modal-footer button >> text=ยกเลิก
    Wait For Elements State    ${BF_SCAN_INPUT}    detached    timeout=10s
    Get Property    ${BF_EQUIPMENT_CODE}    value    ==    ${EMPTY}
    Click    ${BF_SCAN}
    Wait For Elements State    ${BF_SCAN_INPUT}    visible    timeout=10s
    Fill Text    ${BF_SCAN_INPUT}    ${EQUIPMENT}[code]
    Capture Page    77-borrow-scan-popup
    Keyboard Key    press    Enter
    Wait For Elements State    ${BF_SCAN_INPUT}    detached    timeout=10s
    Get Property    ${BF_EQUIPMENT_NAME}    value    ==    ${EQUIPMENT}[name]
    Get Property    ${BF_EQUIPMENT_CODE}    value    ==    ${EQUIPMENT}[code]
    Get Text    ${BF_EQUIPMENT}    contains    ${EQUIPMENT}[code]
    # ปุ่ม "ค้นหา" ใน popup ให้ผลเหมือนกด Enter
    Click    ${BF_SCAN}
    Wait For Elements State    ${BF_SCAN_INPUT}    visible    timeout=10s
    Fill Text    ${BF_SCAN_INPUT}    ${SMALL}[code]
    Click    css=.ant-modal-footer button >> text=ค้นหา
    Wait For Elements State    ${BF_SCAN_INPUT}    detached    timeout=10s
    Get Property    ${BF_EQUIPMENT_CODE}    value    ==    ${SMALL}[code]
