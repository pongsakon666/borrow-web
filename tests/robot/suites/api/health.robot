*** Settings ***
Documentation     ตรวจว่า BE ตอบ health / ready
Resource          ../../resources/common.resource
Test Tags         smoke    api


*** Test Cases ***
Health Endpoint Returns OK
    ${resp}=    GET    ${API_URL}/health    expected_status=200
    Should Be Equal    ${resp.json()}[status]    ok

Ready Endpoint Returns OK
    ${resp}=    GET    ${API_URL}/ready    expected_status=200
    Should Be Equal    ${resp.json()}[status]    ok
