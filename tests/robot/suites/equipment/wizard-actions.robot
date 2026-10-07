*** Settings ***
Documentation     ทดสอบทุก action ของ wizard เพิ่มครุภัณฑ์ (ส่วนที่ add-product.robot ยังไม่ครอบคลุม)
...               — ปุ่ม −/+ จำนวน, สี/หมวดหมู่ย่อย, อัปโหลดไฟล์/ลิงก์/ลบไฟล์, ปุ่มลัด "แก้ไข"/"จัดการรูปภาพ",
...               Save as Draft, ยกเลิก (modal แดง) และ modal ยืนยันที่กดยกเลิกแล้วต้องไม่บันทึก
Resource          ../../resources/common.resource
Resource          ../../resources/api_client.resource
Suite Setup       Run Keywords    Open App    /login    AND    Start Fresh Session    AND    Create Api Session
Suite Teardown    Close App
Test Setup        Open Wizard
Test Tags         equipment    wizard    ui


*** Variables ***
${IMAGE_LINK}     https://example.com/images/e2e-camera.png


*** Keywords ***
Open Wizard
    Go To    ${BASE_URL}/equipment/new
    Reload
    Wait For Elements State    ${WIZARD}    visible    timeout=20s
    Wizard Should Be On Step    1

Unique Code
    ${stamp}=    Get Time    epoch
    ${rand}=    Evaluate    random.randint(100, 999)    modules=random
    RETURN    E2E-W${stamp}${rand}

Fill Required Info
    [Arguments]    ${name}    ${code}
    Fill Equipment Info    ${name}    ${code}    ${SEED_CATEGORY}    3    990

Go To Review Step
    Go To Next Step
    Wizard Should Be On Step    2
    Go To Next Step
    Wizard Should Be On Step    3

Completion Should Be
    [Arguments]    ${pct}
    Wait For Condition    Text    ${WIZARD_PROGRESS} >> css=.eq-footer__pct    ==    ${pct}%    timeout=5s


*** Test Cases ***
Quantity Stepper Increments And Decrements
    [Documentation]    ปุ่ม + / − ปรับจำนวนทั้งใน input และตัวเลขกลาง ต่ำสุดคือ 1
    Get Text    ${QTY_VALUE}    ==    0
    Click    ${QTY_PLUS}
    Quantity Should Be    1
    Click    ${QTY_PLUS}
    Click    ${QTY_PLUS}
    Quantity Should Be    3
    Click    ${QTY_MINUS}
    Quantity Should Be    2
    Click    ${QTY_MINUS}
    Click    ${QTY_MINUS}
    Quantity Should Be    1
    # พิมพ์เองแล้วกด + ต้องต่อจากค่าที่พิมพ์
    Clear Number Field    ${FIELD_QUANTITY}    10
    Click    ${QTY_PLUS}
    Quantity Should Be    11
    Capture Page    88-wizard-quantity-stepper

Completion Progress Reaches 100 With Image
    [Documentation]    ช่องบังคับ 5 ช่อง = 80% · แนบรูปอย่างน้อย 1 ไฟล์ = +20%
    Completion Should Be    0
    ${code}=    Unique Code
    Fill Required Info    ครุภัณฑ์ทดสอบ progress    ${code}
    Completion Should Be    80
    Go To Next Step
    Upload Sample Image
    Completion Should Be    100

Colour And Sub Category Appear In Review
    ${code}=    Unique Code
    Fill Required Info    ครุภัณฑ์ทดสอบสี    ${code}
    Fill Text    ${FIELD_COLOR}    น้ำเงินเข้ม
    Fill Sub Category    เครื่องพิมพ์เลเซอร์
    Go To Review Step
    Get Text    ${REVIEW_COLOR}    contains    น้ำเงินเข้ม
    Get Text    ${REVIEW_SUB_CATEGORY}    ==    เครื่องพิมพ์เลเซอร์
    Get Text    ${REVIEW_NO_FILES}    contains    ยังไม่มีรูปภาพ
    Capture Page    89-wizard-review-colour

Sub Category Suggests Names From Same Category
    [Documentation]    หมวดหมู่ย่อยแนะนำชื่อครุภัณฑ์ที่มีอยู่แล้วในหมวดเดียวกัน
    Select Category    ${SEED_CATEGORY}
    Click    ${FIELD_SUB_CATEGORY}
    Fill Text    ${FIELD_SUB_CATEGORY}    Laser
    Wait For Elements State    css=.ant-select-dropdown:not(.ant-select-dropdown-hidden) .ant-select-item-option >> nth=0    visible    timeout=10s
    Get Text    css=.ant-select-dropdown:not(.ant-select-dropdown-hidden)    contains    ${SEED_EQUIPMENT_NAME}
    Click    css=.ant-select-dropdown:not(.ant-select-dropdown-hidden) .ant-select-item-option >> text=${SEED_EQUIPMENT_NAME}
    Get Property    ${FIELD_SUB_CATEGORY}    value    ==    ${SEED_EQUIPMENT_NAME}

Upload File Add Link And Remove File
    [Documentation]    ขั้น 2: เลือกไฟล์ png, เพิ่มลิงก์รูป (Enter), ลิงก์ผิดรูปแบบถูกเตือน, ลบไฟล์ได้
    ${code}=    Unique Code
    Fill Required Info    ครุภัณฑ์ทดสอบอัปโหลด    ${code}
    Go To Next Step
    Wizard Should Be On Step    2
    Get Element Count    ${UPLOADED_FILES}    ==    0
    Upload Sample Image
    Uploaded File Count Should Be    1
    Get Text    ${UPLOADED_FILE_ITEM} >> nth=0    contains    e2e-sample.png
    Get Text    ${UPLOADED_FILE_ITEM} >> nth=0    contains    KB
    Add Image Link    ${IMAGE_LINK}
    Uploaded File Count Should Be    2
    Get Text    ${UPLOADED_FILE_ITEM} >> nth=1    contains    e2e-camera.png
    Get Text    ${UPLOADED_FILE_ITEM} >> nth=1    contains    ลิงก์ภายนอก
    Get Property    ${FIELD_LINK}    value    ==    ${EMPTY}
    # ลิงก์ที่ไม่ใช่ http(s) ต้องถูกปฏิเสธ
    Add Image Link    ftp://example.com/x.png
    Wait For Elements State    ${ANT_MESSAGE} >> text=ลิงก์ต้องขึ้นต้นด้วย    visible    timeout=10s
    Uploaded File Count Should Be    2
    Capture Page    90-wizard-uploaded-files
    Remove Uploaded File    e2e-sample.png
    Uploaded File Count Should Be    1
    Get Text    ${UPLOADED_FILES}    not contains    e2e-sample.png
    Remove Uploaded File    e2e-camera.png
    Uploaded File Count Should Be    0

Review Shows Files And Shortcut Chips Jump Back
    [Documentation]    ขั้นตรวจสอบแสดงรูปทั้งหมด (รูปแรก = หลัก) · "แก้ไข" → ขั้น 1 · "จัดการรูปภาพ" → ขั้น 2
    ${code}=    Unique Code
    Fill Required Info    ครุภัณฑ์ทดสอบปุ่มลัด    ${code}
    Go To Next Step
    Upload Sample Image
    Add Image Link    ${IMAGE_LINK}
    Uploaded File Count Should Be    2
    Go To Next Step
    Wizard Should Be On Step    3
    Get Element Count    ${REVIEW_FILE_ITEM}    ==    2
    Get Text    ${REVIEW_FILE_ITEM} >> nth=0    contains    หลัก
    Get Text    ${REVIEW_FILE_ITEM} >> nth=1    contains    เสริม
    Capture Page    91-wizard-review-files
    Click    ${REVIEW_EDIT_INFO}
    Wizard Should Be On Step    1
    Get Property    ${FIELD_CODE}    value    ==    ${code}
    Go To Review Step
    Click    ${REVIEW_EDIT_MEDIA}
    Wizard Should Be On Step    2
    Uploaded File Count Should Be    2
    # คลิกชื่อขั้นในแถบซ้ายเพื่อย้อนกลับได้ (เดินหน้าข้ามขั้นไม่ได้)
    Click    ${WIZARD_STEP_3}
    Wizard Should Be On Step    2
    Click    ${WIZARD_STEP_1}
    Wizard Should Be On Step    1

Save As Draft Requires Name Code And Category
    [Documentation]    ยังไม่กรอกข้อมูลหลัก → ขึ้นเตือนและไม่เปิด modal
    Click    ${WIZARD_DRAFT}
    Wait For Elements State    ${ANT_MESSAGE} >> text=กรอกชื่อ รหัส และหมวดหมู่ก่อนบันทึกฉบับร่าง    visible    timeout=10s
    Get Element Count    ${DRAFT_MODAL}    ==    0

Draft Modal Cancel Keeps Form
    ${code}=    Unique Code
    Fill Text    ${FIELD_NAME}    ครุภัณฑ์ฉบับร่างที่ยกเลิก
    Fill Text    ${FIELD_CODE}    ${code}
    Select Category    ${SEED_CATEGORY}
    Open Draft Modal
    Get Text    ${DRAFT_MODAL}    contains    ต้องการบันทึกเป็นฉบับร่างใช่ไหม?
    Click    ${DRAFT_CANCEL}
    Modal Should Be Closed    ${DRAFT_MODAL}
    Wizard Should Be On Step    1
    Get Property    ${FIELD_CODE}    value    ==    ${code}
    Equipment Should Not Be Listed    ${code}

Save As Draft Saves A Hidden Draft
    [Documentation]    กรอกแค่ชื่อ/รหัส/หมวดหมู่ → Save as Draft → ยืนยัน → บันทึกเป็น isDraft
    ...                ฉบับร่างไม่แสดงในรายการ (GET /equipment กรอง isDraft ออก) แต่รหัสถูกจองแล้ว (409)
    [Tags]    critical
    ${code}=    Unique Code
    Fill Text    ${FIELD_NAME}    ครุภัณฑ์ฉบับร่าง ${code}
    Fill Text    ${FIELD_CODE}    ${code}
    Select Category    ${SEED_CATEGORY}
    Open Draft Modal
    Capture Page    92-wizard-draft-modal
    Click    ${DRAFT_OK}
    Wait For Elements State    ${EQ_LIST}    visible    timeout=20s
    Wait For Elements State    ${ANT_MESSAGE} >> text=บันทึกฉบับร่างแล้ว    visible    timeout=10s
    Url Should Be    /reports
    Equipment Should Not Be Listed    ${code}
    Equipment Code Should Exist    ${code}

Cancel Button Danger Modal Cancel Keeps Page
    ${code}=    Unique Code
    Fill Required Info    ครุภัณฑ์ที่ไม่ยกเลิก    ${code}
    Open Cancel Modal
    Get Text    ${CANCEL_MODAL}    contains    ต้องการยกเลิกรายการบันทึก?
    Get Text    ${CANCEL_OK}    ==    ลบ
    Capture Page    93-wizard-cancel-modal
    Click    ${CANCEL_CANCEL}
    Modal Should Be Closed    ${CANCEL_MODAL}
    Url Should Be    /equipment/new
    Get Property    ${FIELD_CODE}    value    ==    ${code}

Cancel Button Danger Modal Ok Leaves Without Saving
    ${code}=    Unique Code
    Fill Required Info    ครุภัณฑ์ที่ถูกยกเลิก    ${code}
    Open Cancel Modal
    Click    ${CANCEL_OK}
    Wait For Elements State    ${EQ_LIST}    visible    timeout=20s
    Url Should Be    /reports
    Equipment Should Not Be Listed    ${code}

Confirm Modal Cancel Does Not Save
    ${code}=    Unique Code
    Fill Required Info    ครุภัณฑ์ที่ไม่ยืนยัน    ${code}
    Go To Review Step
    Open Confirm Modal
    Get Text    ${CONFIRM_MODAL}    contains    ยืนยันการบันทึกข้อมูล ?
    Click    ${CONFIRM_CANCEL}
    Modal Should Be Closed    ${CONFIRM_MODAL}
    Wizard Should Be On Step    3
    Url Should Be    /equipment/new
    Equipment Should Not Be Listed    ${code}

Create Equipment With Every Field Saves Them All
    [Documentation]    กรอกทุกช่อง (สี/หมวดหมู่ย่อย/หน่วย/สถานะ/วันที่ซื้อ) + รูป + ลิงก์ → บันทึกจริง
    ...                แล้วตรวจผ่าน API ว่าค่าไปถึง BE (สี/หมวดหมู่ย่อยถูกต่อท้าย description)
    [Tags]    critical
    ${code}=    Unique Code
    ${name}=    Set Variable    ครุภัณฑ์ครบทุกช่อง ${code}
    Fill Equipment Info    ${name}    ${code}    ${SEED_CATEGORY}    4    12500
    Fill Text    ${FIELD_COLOR}    เทา
    Fill Sub Category    โปรเจกเตอร์
    Fill Text    ${FIELD_DEPARTMENT}    ฝ่ายทดสอบระบบ
    Fill Text    css=[data-testid="field-unit"]    เครื่อง
    Click    css=[data-testid="field-status"]
    Click    css=.ant-select-dropdown:not(.ant-select-dropdown-hidden) .ant-select-item-option[title="ซ่อมบำรุง"]
    Click    css=[data-testid="field-purchased-at"]
    Fill Text    css=[data-testid="field-purchased-at"]    01/09/2026
    Keyboard Key    press    Enter
    Fill Text    ${FIELD_DESCRIPTION}    ทดสอบทุกช่อง
    Get Text    css=.eq-editor__count    ==    12/500
    Go To Next Step
    Upload Sample Image
    Add Image Link    ${IMAGE_LINK}
    Go To Next Step
    Wizard Should Be On Step    3
    Get Text    ${REVIEW_QUANTITY}    contains    4 เครื่อง
    Get Text    css=[data-testid="review-status"]    contains    ซ่อมบำรุง
    Get Text    ${PANEL_REVIEW}    contains    01/09/2026
    Submit Wizard
    Wait For Elements State    ${EQ_LIST}    visible    timeout=20s
    Wait For Elements State    ${ANT_MESSAGE} >> text=เพิ่มครุภัณฑ์    visible    timeout=10s
    ${item}=    Equipment Should Be Listed    ${code}
    Should Be Equal    ${item}[name]    ${name}
    Should Be Equal    ${item}[status]    maintenance
    Should Be Equal    ${item}[unit]    เครื่อง
    Should Be Equal As Integers    ${item}[quantity]    4
    Should Be Equal    ${item}[isDraft]    ${False}
    Should Contain    ${item}[description]    ทดสอบทุกช่อง
    Should Contain    ${item}[description]    สี: เทา
    Should Contain    ${item}[description]    หมวดหมู่ย่อย: โปรเจกเตอร์
    Should Contain    ${item}[images]    e2e-sample.png
    Should Contain    ${item}[images]    ${IMAGE_LINK}
    Should Start With    ${item}[purchasedAt]    2026-0
