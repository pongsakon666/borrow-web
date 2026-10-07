*** Settings ***
Documentation     ทดสอบหน้าตั้งค่าโปรไฟล์ — ข้อมูลผู้ใช้ปัจจุบัน, แก้ชื่อ/เบอร์โทร, สวิตช์ Preferences,
...               Save Changes และปุ่มกล้องบนรูปโปรไฟล์
...               (หน้านี้ยังไม่มี API บันทึก — ค่าที่แก้อยู่ใน state ของหน้าเท่านั้น)
Resource          ../../resources/common.resource
Resource          ../../resources/pages/settings_page.resource
Suite Setup       Run Keywords    Open App    /login    AND    Start Fresh Session
Suite Teardown    Close App
Test Setup        Open Settings
Test Tags         settings    ui


*** Keywords ***
Open Settings
    Go To    ${BASE_URL}/settings
    Settings Page Should Be Loaded


*** Test Cases ***
Shows Current User Name Email And Role
    [Tags]    smoke
    Get Text    ${SETTINGS} >> css=.st-head h1    ==    Profile Settings
    Get Text    ${SETTINGS_NAME}    ==    ${USER_NAME}
    Get Text    ${SETTINGS_EMAIL}    ==    ${USER}
    Get Text    ${SETTINGS_ROLE}    ==    ผู้ดูแลระบบ
    Get Property    ${SETTINGS_NAME_INPUT}    value    ==    ${USER_NAME}
    Get Property    ${SETTINGS_PHONE_INPUT}    value    ==    ${EMPTY}
    Capture Page    98-settings-page

Full Name And Phone Can Be Edited
    ${stamp}=    Get Time    epoch
    ${name}=    Set Variable    ชื่อทดสอบ ${stamp}
    Fill Text    ${SETTINGS_NAME_INPUT}    ${name}
    Get Property    ${SETTINGS_NAME_INPUT}    value    ==    ${name}
    Fill Text    ${SETTINGS_PHONE_INPUT}    0812345678
    Get Property    ${SETTINGS_PHONE_INPUT}    value    ==    0812345678
    # ชื่อบนการ์ด/เมนูยังเป็นชื่อจาก session จนกว่าจะมี API บันทึกจริง
    Get Text    ${SETTINGS_NAME}    ==    ${USER_NAME}
    Get Text    ${HEADER_USER}    ==    ${USER_NAME}

Preference Switches Toggle
    [Documentation]    ค่าเริ่มต้น Email=เปิด, Dark=ปิด, 2FA=เปิด · คลิกแล้วสลับ · คลิกซ้ำกลับค่าเดิม
    Switch Should Be    ${SETTINGS_PREF_EMAIL}    true
    Switch Should Be    ${SETTINGS_PREF_DARK}    false
    Switch Should Be    ${SETTINGS_PREF_2FA}    true
    Click    ${SETTINGS_PREF_EMAIL}
    Click    ${SETTINGS_PREF_DARK}
    Click    ${SETTINGS_PREF_2FA}
    Switch Should Be    ${SETTINGS_PREF_EMAIL}    false
    Switch Should Be    ${SETTINGS_PREF_DARK}    true
    Switch Should Be    ${SETTINGS_PREF_2FA}    false
    Capture Page    98-settings-switches
    Click    ${SETTINGS_PREF_DARK}
    Switch Should Be    ${SETTINGS_PREF_DARK}    false

Save Changes Shows Success Message
    Fill Text    ${SETTINGS_NAME_INPUT}    ชื่อที่บันทึก
    Click    ${SETTINGS_PREF_DARK}
    Click    ${SETTINGS_SAVE}
    Toast Should Contain    บันทึกการตั้งค่าแล้ว
    # หลังบันทึกค่ายังคงอยู่บนหน้า
    Get Property    ${SETTINGS_NAME_INPUT}    value    ==    ชื่อที่บันทึก
    Switch Should Be    ${SETTINGS_PREF_DARK}    true

Camera Badge Shows Not Supported Message
    Get Attribute    ${SETTINGS_AVATAR}    aria-label    ==    เปลี่ยนรูปโปรไฟล์
    Click    ${SETTINGS_AVATAR}
    Toast Should Contain    ยังไม่รองรับการอัปโหลดรูปโปรไฟล์
    Capture Page    99-settings-camera

Unsaved Values Reset After Leaving Page
    [Documentation]    ยังไม่มี API — ออกจากหน้าแล้วกลับมา ค่าต้องกลับเป็นค่าจาก session
    Fill Text    ${SETTINGS_NAME_INPUT}    ชื่อชั่วคราว
    Click    ${SETTINGS_PREF_EMAIL}
    Navigate To    ${NAV_DASHBOARD}    Dashboard
    Navigate To    ${NAV_SETTINGS}    Settings
    Settings Page Should Be Loaded
    Get Property    ${SETTINGS_NAME_INPUT}    value    ==    ${USER_NAME}
    Switch Should Be    ${SETTINGS_PREF_EMAIL}    true
