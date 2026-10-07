*** Settings ***
Documentation     เรียก API ตรง ๆ เพื่อเตรียม/ตรวจข้อมูลให้ UI test (ไม่ผ่าน browser)
...               ใช้ใน suite ของปฏิทิน และ wizard (ตรวจว่าฉบับร่างถูกบันทึกจริง)
Library           RequestsLibrary
Library           Collections
Library           DateTime
Variables         variables.py


*** Variables ***
${API}    ${API_URL}/api/v1


*** Keywords ***
Create Api Session
    [Documentation]    ล็อกอินผ่าน API แล้วเก็บ Authorization header ไว้ใช้ทั้ง suite
    ${body}=    Create Dictionary    email=${USER}    password=${PASSWORD}
    ${resp}=    POST    ${API}/auth/login    json=${body}    expected_status=200
    ${headers}=    Create Dictionary    Authorization=Bearer ${resp.json()}[accessToken]
    Set Suite Variable    ${API_HEADERS}    ${headers}

Find Available Equipment
    [Documentation]    หาครุภัณฑ์พร้อมใช้ที่ยังเหลือให้ยืมอย่างน้อย 1 ชิ้น
    ${params}=    Create Dictionary    status=ready    limit=100
    ${resp}=    GET    ${API}/equipment    headers=${API_HEADERS}    params=${params}    expected_status=200
    ${items}=    Set Variable    ${resp.json()}[items]
    FOR    ${item}    IN    @{items}
        IF    ${item}[quantity] - ${item}[borrowedQuantity] > 0    RETURN    ${item}
    END
    Fail    ไม่พบครุภัณฑ์ที่ยังเหลือให้ยืม

Create Borrow Transaction For Today
    [Arguments]    ${note}=Robot E2E
    [Documentation]    สร้างรายการยืม 1 ชิ้น (occurredAt = ตอนนี้) กำหนดคืนอีก 2 ชั่วโมง
    ${equipment}=    Find Available Equipment
    ${due}=    Get Current Date    UTC    increment=2 hours    result_format=%Y-%m-%dT%H:%M:%S.000Z
    ${body}=    Create Dictionary
    ...    type=borrow    equipmentId=${equipment}[id]    quantity=${1}    dueAt=${due}    note=${note}
    ${resp}=    POST    ${API}/transactions    json=${body}    headers=${API_HEADERS}    expected_status=201
    RETURN    ${resp.json()}

Reject Transaction
    [Arguments]    ${id}
    [Documentation]    teardown — ปฏิเสธรายการเพื่อคืนจำนวนที่ถูกกันไว้ให้ครุภัณฑ์ (รันซ้ำได้ไม่กินสต็อก)
    ${body}=    Create Dictionary    status=rejected
    PATCH    ${API}/transactions/${id}/status    json=${body}    headers=${API_HEADERS}    expected_status=200

Equipment Code Should Exist
    [Arguments]    ${code}
    [Documentation]    รายการฉบับร่างไม่แสดงใน GET /equipment — พิสูจน์ว่ามีอยู่จริงด้วยการสร้างรหัสซ้ำแล้วได้ 409
    ${body}=    Create Dictionary    code=${code}    name=ตรวจรหัสซ้ำ    category=${SEED_CATEGORY}
    POST    ${API}/equipment    json=${body}    headers=${API_HEADERS}    expected_status=409

Equipment Should Not Be Listed
    [Arguments]    ${code}
    ${params}=    Create Dictionary    search=${code}
    ${resp}=    GET    ${API}/equipment    headers=${API_HEADERS}    params=${params}    expected_status=200
    Should Be Equal As Integers    ${resp.json()}[total]    0

Equipment Should Be Listed
    [Arguments]    ${code}
    ${params}=    Create Dictionary    search=${code}
    ${resp}=    GET    ${API}/equipment    headers=${API_HEADERS}    params=${params}    expected_status=200
    Should Be Equal As Integers    ${resp.json()}[total]    1
    RETURN    ${resp.json()}[items][0]

Get Transaction
    [Arguments]    ${id}
    ${resp}=    GET    ${API}/transactions/${id}    headers=${API_HEADERS}    expected_status=200
    RETURN    ${resp.json()}
