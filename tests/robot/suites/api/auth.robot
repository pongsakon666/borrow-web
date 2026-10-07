*** Settings ***
Documentation     ทดสอบ auth API ตรง ๆ (ไม่ผ่าน browser) — ต้องมี BE :3001 รันอยู่
Resource          ../../resources/common.resource
Test Tags         api    auth


*** Variables ***
${LOGIN_ENDPOINT}     ${API_URL}/api/v1/auth/login
${ME_ENDPOINT}        ${API_URL}/api/v1/auth/me


*** Test Cases ***
Login Returns Access Token And Profile
    [Tags]    smoke
    ${body}=    Create Dictionary    email=${USER}    password=${PASSWORD}
    ${resp}=    POST    ${LOGIN_ENDPOINT}    json=${body}    expected_status=200
    Should Not Be Empty    ${resp.json()}[accessToken]
    Should Be Equal    ${resp.json()}[user][email]    ${USER}
    Should Be Equal    ${resp.json()}[user][role]    admin

Me Returns Current User With Token
    ${body}=    Create Dictionary    email=${USER}    password=${PASSWORD}
    ${login}=    POST    ${LOGIN_ENDPOINT}    json=${body}    expected_status=200
    ${headers}=    Create Dictionary    Authorization=Bearer ${login.json()}[accessToken]
    ${resp}=    GET    ${ME_ENDPOINT}    headers=${headers}    expected_status=200
    Should Be Equal    ${resp.json()}[email]    ${USER}

Login With Wrong Password Returns 401
    ${body}=    Create Dictionary    email=${USER}    password=WrongPassword123
    ${resp}=    POST    ${LOGIN_ENDPOINT}    json=${body}    expected_status=401
    Should Be Equal    ${resp.json()}[message]    อีเมลหรือรหัสผ่านไม่ถูกต้อง

Login With Invalid Email Returns 400
    ${body}=    Create Dictionary    email=not-an-email    password=${PASSWORD}
    POST    ${LOGIN_ENDPOINT}    json=${body}    expected_status=400

Me Without Token Returns 401
    GET    ${ME_ENDPOINT}    expected_status=401
