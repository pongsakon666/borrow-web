*** Settings ***
Documentation     Page Object ของ wizard เพิ่มครุภัณฑ์ และหน้า Product Reports
Library           Browser
Variables         ../variables.py


*** Variables ***
# ── wizard ──
${WIZARD}              css=[data-testid="equipment-form-page"]
${WIZARD_STEPS}        css=[data-testid="wizard-steps"]
${WIZARD_STEP_1}       css=[data-testid="wizard-step-1"]
${WIZARD_STEP_2}       css=[data-testid="wizard-step-2"]
${WIZARD_STEP_3}       css=[data-testid="wizard-step-3"]
${PANEL_INFO}          css=[data-testid="wizard-panel-info"]
${PANEL_MEDIA}         css=[data-testid="wizard-panel-media"]
${PANEL_REVIEW}        css=[data-testid="wizard-panel-review"]
${WIZARD_NEXT}         css=[data-testid="wizard-next"]
${WIZARD_BACK}         css=[data-testid="wizard-back"]
${WIZARD_SUBMIT}       css=[data-testid="wizard-submit"]
${WIZARD_DRAFT}        css=[data-testid="wizard-draft"]
${WIZARD_PROGRESS}     css=[data-testid="wizard-progress"]

${FIELD_NAME}          css=[data-testid="field-name"]
${FIELD_CODE}          css=[data-testid="field-code"]
${FIELD_CATEGORY}      css=[data-testid="field-category"]
${FIELD_DEPARTMENT}    css=[data-testid="field-department"]
${FIELD_QUANTITY}      css=[data-testid="field-quantity"]
${FIELD_PRICE}         css=[data-testid="field-price"]
${FIELD_DESCRIPTION}   css=[data-testid="field-description"]

${REVIEW_NAME}         css=[data-testid="review-name"]
${REVIEW_CODE}         css=[data-testid="review-code"]
${REVIEW_CATEGORY}     css=[data-testid="review-category"]
${REVIEW_QUANTITY}     css=[data-testid="review-quantity"]
${REVIEW_PRICE}        css=[data-testid="review-price"]

# ── reports ──
${EQ_LIST}             css=[data-testid="equipment-list-page"]
${EQ_TABLE}            css=[data-testid="eq-table"]
${EQ_SEARCH}           css=[data-testid="eq-search"]
${EQ_CATEGORY}         css=[data-testid="eq-category"]
${EQ_ADD}              css=[data-testid="eq-add"]

${FIELD_ERROR_MSG}     css=.ant-form-item-explain-error
${ANT_MESSAGE}         css=.ant-message-notice


*** Keywords ***
Wizard Should Be On Step
    [Arguments]    ${step}
    [Documentation]    ตรวจว่า panel ของขั้นที่ระบุแสดงอยู่ (ขั้นอื่นถูกซ่อนด้วย hidden)
    ${panel}=    Set Variable If
    ...    '${step}' == '1'    ${PANEL_INFO}
    ...    '${step}' == '2'    ${PANEL_MEDIA}
    ...    ${PANEL_REVIEW}
    Wait For Elements State    ${panel}    visible    timeout=10s

Fill Equipment Info
    [Arguments]    ${name}    ${code}    ${category}=${SEED_CATEGORY}    ${quantity}=5    ${price}=1500
    Fill Text    ${FIELD_NAME}    ${name}
    Fill Text    ${FIELD_CODE}    ${code}
    Select Category    ${category}
    Clear Number Field    ${FIELD_QUANTITY}    ${quantity}
    Clear Number Field    ${FIELD_PRICE}    ${price}

Select Category
    [Arguments]    ${category}
    [Documentation]    antd Select — ต้องคลิกเปิดก่อนแล้วเลือกจาก dropdown
    Click    ${FIELD_CATEGORY}
    Wait For Elements State    css=.ant-select-dropdown    visible    timeout=10s
    Click    css=.ant-select-item-option[title="${category}"]

Clear Number Field
    [Arguments]    ${locator}    ${value}
    Click    ${locator}
    Keyboard Key    press    Control+a
    Fill Text    ${locator}    ${value}

Go To Next Step
    Click    ${WIZARD_NEXT}

Submit Wizard
    Click    ${WIZARD_SUBMIT}
    # ปุ่มยืนยันจะเปิด modal ก่อนบันทึกจริง
    Click    css=[data-testid="wizard-confirm-ok"]

Progress Should Be At Least
    [Arguments]    ${minimum}
    [Documentation]    อ่าน % จาก aria-valuenow ของ antd Progress
    ${value}=    Get Attribute    ${WIZARD_PROGRESS} >> css=.ant-progress-track    style
    Should Not Be Empty    ${value}

# ── ส่วนเพิ่มเติมสำหรับ wizard-actions.robot / reports-actions.robot ──
*** Variables ***
${FIELD_COLOR}           css=[data-testid="field-color"]
${FIELD_SUB_CATEGORY}    css=[data-testid="field-sub-category"] input
${QTY_MINUS}             css=[data-testid="field-quantity-minus"]
${QTY_PLUS}              css=[data-testid="field-quantity-plus"]
${QTY_VALUE}             css=.eq-qty__value
${FIELD_UPLOAD_INPUT}    css=input[data-testid="field-upload"]
${FIELD_LINK}            css=[data-testid="field-link"]
${UPLOADED_FILES}        css=[data-testid="uploaded-files"]
${UPLOADED_FILE_ITEM}    css=[data-testid="uploaded-files"] li.eq-file
${REMOVE_FILE}           css=[data-testid="remove-file"]
${WIZARD_CANCEL}         css=[data-testid="wizard-cancel"]

${REVIEW_SUB_CATEGORY}   css=[data-testid="review-sub-category"]
${REVIEW_COLOR}          css=[data-testid="review-color"]
${REVIEW_FILES}          css=[data-testid="review-files"]
${REVIEW_FILE_ITEM}      css=[data-testid="review-files"] li.eq-thumb
${REVIEW_NO_FILES}       css=.eq-review__none
${REVIEW_EDIT_INFO}      css=[data-testid="review-edit-info"]
${REVIEW_EDIT_MEDIA}     css=[data-testid="review-edit-media"]

${CONFIRM_MODAL}         css=[data-testid="wizard-confirm"]
${CONFIRM_OK}            css=[data-testid="wizard-confirm-ok"]
${CONFIRM_CANCEL}        css=[data-testid="wizard-confirm-cancel"]
${DRAFT_MODAL}           css=[data-testid="wizard-draft-modal"]
${DRAFT_OK}              css=[data-testid="wizard-draft-modal-ok"]
${DRAFT_CANCEL}          css=[data-testid="wizard-draft-modal-cancel"]
${CANCEL_MODAL}          css=[data-testid="wizard-cancel-modal"]
${CANCEL_OK}             css=[data-testid="wizard-cancel-modal-ok"]
${CANCEL_CANCEL}         css=[data-testid="wizard-cancel-modal-cancel"]

${SAMPLE_IMAGE}          ${CURDIR}/../files/e2e-sample.png

# ── reports ──
${EQ_ROWS}               css=[data-testid="eq-table"] >> css=tbody tr.ant-table-row
${EQ_STATUS_FILTER}      css=[data-testid="eq-status-filter"]
${EQ_PAGINATION}         css=.rp-table-card .ant-pagination
${REPORT_RANGE}          css=.rp-range
${REPORT_RANGE_START}    css=input[data-testid="report-range"][date-range="start"]
${REPORT_RANGE_END}      css=input[data-testid="report-range"][date-range="end"]
${REPORT_EXPORT}         css=[data-testid="report-export"]
${REPORT_TREND}          css=[data-testid="report-trend"]
${REPORT_STATUS}         css=[data-testid="report-status"]
${PICKER_OPEN}           css=.ant-picker-dropdown:not(.ant-picker-dropdown-hidden)
${OPEN_DROPDOWN_ITEM}    css=.ant-dropdown:not(.ant-dropdown-hidden) .ant-dropdown-menu-item


*** Keywords ***
Quantity Should Be
    [Arguments]    ${expected}
    [Documentation]    ตรวจทั้งค่าใน input และตัวเลขกลางปุ่ม −/+
    Get Property    ${FIELD_QUANTITY}    value    ==    ${expected}
    Get Text    ${QTY_VALUE}    ==    ${expected}

Fill Sub Category
    [Arguments]    ${text}
    [Documentation]    AutoComplete — พิมพ์ค่าอิสระได้ แล้วกด Escape ปิดรายการแนะนำ
    Fill Text    ${FIELD_SUB_CATEGORY}    ${text}
    Keyboard Key    press    Escape

Upload Sample Image
    [Documentation]    ใส่ไฟล์เข้า <input type=file> ที่ซ่อนอยู่ใน Upload.Dragger
    Upload File By Selector    ${FIELD_UPLOAD_INPUT}    ${SAMPLE_IMAGE}
    Wait For Elements State    ${UPLOADED_FILES}    visible    timeout=10s

Add Image Link
    [Arguments]    ${url}
    Fill Text    ${FIELD_LINK}    ${url}
    Keyboard Key    press    Enter

Uploaded File Count Should Be
    [Arguments]    ${expected}
    IF    ${expected} == 0
        Wait For Elements State    ${UPLOADED_FILES}    detached    timeout=10s
    ELSE
        Wait For Condition    Element Count    ${UPLOADED_FILE_ITEM}    ==    ${expected}    timeout=10s
    END

Remove Uploaded File
    [Arguments]    ${name}
    Click    ${UPLOADED_FILE_ITEM} >> text=${name} >> xpath=ancestor::li[1] >> ${REMOVE_FILE}

Open Draft Modal
    Click    ${WIZARD_DRAFT}
    Wait For Elements State    ${DRAFT_MODAL}    visible    timeout=10s

Open Cancel Modal
    Click    ${WIZARD_CANCEL}
    Wait For Elements State    ${CANCEL_MODAL}    visible    timeout=10s

Open Confirm Modal
    Click    ${WIZARD_SUBMIT}
    Wait For Elements State    ${CONFIRM_MODAL}    visible    timeout=10s

Modal Should Be Closed
    [Arguments]    ${modal}
    Wait For Elements State    ${modal}    detached    timeout=10s

# ── reports ──
Reports Page Should Be Loaded
    Wait For Elements State    ${EQ_LIST}    visible    timeout=20s
    Wait Until Keyword Succeeds    10x    1s    Equipment Rows Should Exist

Equipment Rows Should Exist
    ${rows}=    Get Element Count    ${EQ_ROWS}
    Should Be True    ${rows} > 0    ตารางครุภัณฑ์ต้องมีข้อมูล

Report Kpi Should Have Number
    [Arguments]    ${testid}
    ${text}=    Get Text    css=[data-testid="${testid}-value"]
    ${clean}=    Evaluate    $text.replace(',', '')
    Should Match Regexp    ${clean}    ^\\d+$

Filter Equipment By Status
    [Arguments]    ${label}
    [Documentation]    ปุ่ม "กรองตาราง" เปิด dropdown สถานะ
    Click    ${EQ_STATUS_FILTER}
    Wait For Elements State    ${OPEN_DROPDOWN_ITEM} >> nth=0    visible    timeout=10s
    Click    ${OPEN_DROPDOWN_ITEM} >> text="${label}"

Pick Report Range
    [Arguments]    ${start}    ${end}
    [Documentation]    เลือกช่วงวันที่ใน RangePicker ด้วย title ของช่องวัน (รูปแบบ YYYY-MM-DD)
    Click    ${REPORT_RANGE_START}
    Wait For Elements State    ${PICKER_OPEN}    visible    timeout=10s
    Click    ${PICKER_OPEN} >> css=td[title="${start}"]
    Click    ${PICKER_OPEN} >> css=td[title="${end}"]
    Wait For Elements State    ${PICKER_OPEN}    hidden    timeout=10s
