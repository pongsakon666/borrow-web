*** Settings ***
Documentation     ทดสอบ wizard เพิ่มครุภัณฑ์ 3 ขั้น — validate, เดินหน้า/ถอยหลัง, บันทึกจริง
Resource          ../../resources/common.resource
Library           String
Suite Setup       Run Keywords    Open App    /login    AND    Start Fresh Session
Suite Teardown    Close App
Test Setup        Open Add Product Page
Test Tags         equipment    wizard    ui


*** Keywords ***
Open Add Product Page
    [Documentation]    เปิดหน้าใหม่ทุก test เพื่อล้างค่าในฟอร์มจากเทสต์ก่อนหน้า
    Go To    ${BASE_URL}/equipment/new
    Reload
    Wait For Elements State    ${WIZARD}    visible    timeout=20s
    Wizard Should Be On Step    1

Unique Code
    [Documentation]    รหัสครุภัณฑ์ต้องไม่ซ้ำ — ผูกกับเวลาเพื่อให้รันซ้ำได้
    ${stamp}=    Get Time    epoch
    RETURN    E2E-${stamp}


*** Test Cases ***
Wizard Starts At Step One
    [Documentation]    เปิดมาอยู่ขั้น "ข้อมูลครุภัณฑ์" และมีฟิลด์ครบ
    [Tags]    smoke
    Wait For Elements State    ${WIZARD_STEPS}    visible
    Get Text    ${WIZARD_STEP_1}    contains    ข้อมูลครุภัณฑ์
    Get Text    ${WIZARD_STEP_2}    contains    อัปโหลดรูปภาพ
    Get Text    ${WIZARD_STEP_3}    contains    ตรวจสอบและบันทึก
    FOR    ${field}    IN    ${FIELD_NAME}    ${FIELD_CODE}    ${FIELD_CATEGORY}    ${FIELD_QUANTITY}    ${FIELD_PRICE}
        Wait For Elements State    ${field}    visible
    END
    Capture Page    30-wizard-step1

Cannot Go Next With Empty Required Fields
    [Documentation]    กด "ถัดไป" โดยไม่กรอก → ขึ้น error และยังอยู่ขั้น 1
    Go To Next Step
    Wait For Elements State    ${FIELD_ERROR_MSG} >> nth=0    visible    timeout=10s
    Get Text    ${FIELD_ERROR_MSG} >> nth=0    ==    กรุณากรอกชื่อครุภัณฑ์
    Wizard Should Be On Step    1
    Capture Page    31-wizard-validation

Progress Increases While Filling Form
    [Documentation]    แถบ Product completion ต้องขยับตามจำนวนฟิลด์ที่กรอก
    ${code}=    Unique Code
    Fill Equipment Info    ครุภัณฑ์ทดสอบความคืบหน้า    ${code}
    Wait For Elements State    ${WIZARD_PROGRESS}    visible
    ${text}=    Get Text    ${WIZARD_PROGRESS}
    Should Contain    ${text}    %
    Capture Page    32-wizard-progress

Can Move Between Steps
    [Documentation]    ขั้น 1 → 2 → 3 แล้วย้อนกลับได้ ข้อมูลยังอยู่
    ${code}=    Unique Code
    Fill Equipment Info    ครุภัณฑ์ทดสอบการเดินขั้น    ${code}
    Go To Next Step
    Wizard Should Be On Step    2
    Capture Page    33-wizard-step2
    Go To Next Step
    Wizard Should Be On Step    3
    Get Text    ${REVIEW_CODE}    ==    ${code}
    Click    ${WIZARD_BACK}
    Wizard Should Be On Step    2
    Click    ${WIZARD_BACK}
    Wizard Should Be On Step    1
    # ย้อนกลับมาแล้วค่าที่กรอกต้องยังอยู่ (input ต้องอ่านจาก property value ไม่ใช่ text)
    ${kept}=    Get Property    ${FIELD_CODE}    value
    Should Be Equal    ${kept}    ${code}

Review Step Shows Entered Data
    [Documentation]    ขั้นตรวจสอบต้องสรุปข้อมูลที่กรอกไว้ครบ
    ${code}=    Unique Code
    Fill Equipment Info    เครื่องทดสอบขั้นตรวจสอบ    ${code}    ${SEED_CATEGORY}    12    2500
    Go To Next Step
    Go To Next Step
    Wizard Should Be On Step    3
    Get Text    ${REVIEW_NAME}    ==    เครื่องทดสอบขั้นตรวจสอบ
    Get Text    ${REVIEW_CODE}    ==    ${code}
    Get Text    ${REVIEW_CATEGORY}    ==    ${SEED_CATEGORY}
    Get Text    ${REVIEW_QUANTITY}    contains    12
    Get Text    ${REVIEW_PRICE}    contains    2,500
    Capture Page    34-wizard-review

Create Equipment End To End
    [Documentation]    กรอก → ถัดไป → ยืนยัน → บันทึกจริง แล้วต้องเจอในหน้า Product Reports
    [Tags]    smoke    critical
    ${code}=    Unique Code
    ${name}=    Set Variable    ครุภัณฑ์จากการทดสอบ ${code}
    Fill Equipment Info    ${name}    ${code}    ${SEED_CATEGORY}    7    3900
    Fill Text    ${FIELD_DEPARTMENT}    ฝ่ายทดสอบระบบ
    Fill Text    ${FIELD_DESCRIPTION}    สร้างโดย Robot Framework
    Go To Next Step
    Go To Next Step
    Submit Wizard

    # บันทึกสำเร็จ → เด้งไปหน้า Product Reports
    Wait For Elements State    ${EQ_LIST}    visible    timeout=20s
    Capture Page    35-wizard-submitted

    # ค้นหาด้วยรหัสที่เพิ่งสร้าง ต้องเจอ 1 แถว
    Fill Text    ${EQ_SEARCH} >> css=input    ${code}
    Keyboard Key    press    Enter
    Wait Until Keyword Succeeds    10x    1s    Table Should Contain    ${code}
    Get Text    ${EQ_TABLE}    contains    ${name}
    Capture Page    36-equipment-created

Duplicate Code Is Rejected By API
    [Documentation]    ใช้รหัสที่มีอยู่แล้วในระบบ → API ตอบ 409 และขึ้น message เตือน
    Fill Equipment Info    ครุภัณฑ์รหัสซ้ำ    ${SEED_EQUIPMENT_CODE}
    Go To Next Step
    Go To Next Step
    Submit Wizard
    Wait For Elements State    ${ANT_MESSAGE}    visible    timeout=20s
    Get Text    ${ANT_MESSAGE}    contains    ถูกใช้ไปแล้ว
    Capture Page    37-wizard-duplicate-code


*** Keywords ***
Table Should Contain
    [Arguments]    ${text}
    Get Text    ${EQ_TABLE}    contains    ${text}
