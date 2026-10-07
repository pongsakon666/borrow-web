*** Settings ***
Documentation     Page Object ของหน้าตั้งค่าโปรไฟล์ (/settings)
Library           Browser
Variables         ../variables.py


*** Variables ***
${SETTINGS}              css=[data-testid="settings-page"]
${SETTINGS_NAME}         css=[data-testid="settings-user-name"]
${SETTINGS_EMAIL}        css=[data-testid="settings-user-email"]
${SETTINGS_ROLE}         css=[data-testid="settings-user-role"]
${SETTINGS_NAME_INPUT}   css=[data-testid="settings-name-input"]
${SETTINGS_PHONE_INPUT}  css=[data-testid="settings-phone-input"]
${SETTINGS_SAVE}         css=[data-testid="settings-save"]
${SETTINGS_AVATAR}       css=[data-testid="settings-avatar-badge"]
${SETTINGS_PREF_EMAIL}   css=[data-testid="settings-pref-email"]
${SETTINGS_PREF_DARK}    css=[data-testid="settings-pref-dark"]
${SETTINGS_PREF_2FA}     css=[data-testid="settings-pref-twoFactor"]
${TOAST}                 css=.ant-message-notice


*** Keywords ***
Settings Page Should Be Loaded
    Wait For Elements State    ${SETTINGS}    visible    timeout=20s
    Wait For Elements State    ${SETTINGS_NAME_INPUT}    visible    timeout=10s

Switch Should Be
    [Arguments]    ${locator}    ${state}
    [Documentation]    antd Switch เป็น <button role=switch aria-checked=true|false>
    Get Attribute    ${locator}    aria-checked    ==    ${state}

Toast Should Contain
    [Arguments]    ${text}
    Wait For Elements State    ${TOAST} >> text=${text}    visible    timeout=10s
