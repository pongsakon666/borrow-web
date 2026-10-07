*** Settings ***
Documentation     ทดสอบ equipment / transactions / dashboard API ตรง ๆ (ไม่ผ่าน browser)
Resource          ../../resources/common.resource
Library           Collections
Suite Setup       Authenticate
Test Tags         api


*** Variables ***
${API}    ${API_URL}/api/v1


*** Keywords ***
Authenticate
    [Documentation]    ล็อกอินหนึ่งครั้งแล้วเก็บ header ไว้ใช้ทั้ง suite
    ${body}=    Create Dictionary    email=${USER}    password=${PASSWORD}
    ${resp}=    POST    ${API}/auth/login    json=${body}    expected_status=200
    ${headers}=    Create Dictionary    Authorization=Bearer ${resp.json()}[accessToken]
    Set Suite Variable    ${AUTH}    ${headers}


*** Test Cases ***
Equipment List Returns Paginated Data
    [Tags]    smoke
    ${resp}=    GET    ${API}/equipment    headers=${AUTH}    params=limit=5    expected_status=200
    Should Be True    ${resp.json()}[total] > 0
    Length Should Be    ${resp.json()}[items]    5
    Dictionary Should Contain Key    ${resp.json()}[items][0]    code
    Dictionary Should Contain Key    ${resp.json()}[items][0]    borrowedQuantity

Equipment Search Finds Seeded Item
    ${params}=    Create Dictionary    search=${SEED_EQUIPMENT_CODE}
    ${resp}=    GET    ${API}/equipment    headers=${AUTH}    params=${params}    expected_status=200
    Should Be Equal As Integers    ${resp.json()}[total]    1
    Should Be Equal    ${resp.json()}[items][0][name]    ${SEED_EQUIPMENT_NAME}

Equipment Categories Are Returned
    ${resp}=    GET    ${API}/equipment/categories    headers=${AUTH}    expected_status=200
    Should Contain    ${resp.json()}    ${SEED_CATEGORY}

Create Equipment Requires Name And Code
    ${body}=    Create Dictionary    category=${SEED_CATEGORY}
    POST    ${API}/equipment    json=${body}    headers=${AUTH}    expected_status=400

Duplicate Equipment Code Returns 409
    ${body}=    Create Dictionary
    ...    code=${SEED_EQUIPMENT_CODE}    name=ซ้ำ    category=${SEED_CATEGORY}
    ${resp}=    POST    ${API}/equipment    json=${body}    headers=${AUTH}    expected_status=409
    Should Contain    ${resp.json()}[message]    ถูกใช้ไปแล้ว

Create And Delete Equipment
    [Documentation]    สร้างแล้วลบทิ้ง เพื่อไม่ให้ข้อมูลทดสอบค้างในระบบ
    ${stamp}=    Get Time    epoch
    ${body}=    Create Dictionary
    ...    code=API-${stamp}    name=ครุภัณฑ์จาก API test    category=${SEED_CATEGORY}
    ...    quantity=${3}    price=${1200}
    ${created}=    POST    ${API}/equipment    json=${body}    headers=${AUTH}    expected_status=201
    Should Be Equal    ${created.json()}[code]    API-${stamp}
    DELETE    ${API}/equipment/${created.json()}[id]    headers=${AUTH}    expected_status=204
    GET    ${API}/equipment/${created.json()}[id]    headers=${AUTH}    expected_status=404

Unknown Equipment Returns 404
    GET    ${API}/equipment/8f0d3c2e-0000-4000-8000-000000000000    headers=${AUTH}    expected_status=404

Transactions Can Be Filtered By Type
    ${params}=    Create Dictionary    type=borrow    limit=10
    ${resp}=    GET    ${API}/transactions    headers=${AUTH}    params=${params}    expected_status=200
    Should Be True    ${resp.json()}[total] > 0
    FOR    ${item}    IN    @{resp.json()}[items]
        Should Be Equal    ${item}[type]    borrow
    END

Borrow More Than Available Is Rejected
    [Documentation]    ยืมเกินจำนวนคงเหลือ → 400 พร้อมข้อความบอกจำนวนที่เหลือ
    ${list}=    GET    ${API}/equipment    headers=${AUTH}    params=limit=1    expected_status=200
    ${id}=    Set Variable    ${list.json()}[items][0][id]
    ${body}=    Create Dictionary    type=borrow    equipmentId=${id}    quantity=${999999}
    ${resp}=    POST    ${API}/transactions    json=${body}    headers=${AUTH}    expected_status=400
    Should Contain    ${resp.json()}[message]    ไม่พอให้ยืม

Dashboard Summary Returns All Sections
    [Tags]    smoke
    ${resp}=    GET    ${API}/dashboard/summary    headers=${AUTH}    params=range=month    expected_status=200
    Length Should Be    ${resp.json()}[cards]    4
    Should Be Equal    ${resp.json()}[cards][0][key]    total
    Should Be True    ${resp.json()}[cards][0][value] > 0
    Length Should Be    ${resp.json()}[yearly]    12
    Should Be True    len(${resp.json()}[usage]) > 0
    Should Be True    len(${resp.json()}[recent]) > 0

Dashboard Requires Authentication
    GET    ${API}/dashboard/summary    expected_status=401

Activities And Notifications Are Returned
    ${activities}=    GET    ${API}/activities    headers=${AUTH}    params=limit=5    expected_status=200
    Should Be True    len(${activities.json()}) > 0
    ${notifications}=    GET    ${API}/notifications    headers=${AUTH}    expected_status=200
    Dictionary Should Contain Key    ${notifications.json()}    unread
    Should Be True    len(${notifications.json()}[items]) > 0

Members List Is Returned
    ${resp}=    GET    ${API}/users    headers=${AUTH}    params=limit=10    expected_status=200
    Should Be True    len(${resp.json()}) > 1
