*** Settings ***
Documentation     ทดสอบ route guard — ผู้ที่ยังไม่ล็อกอินเข้าหน้าหลังบ้านไม่ได้ทุกหน้า
...               และผู้ที่ล็อกอินแล้วเปิด /login จะถูกพาไปหน้า Dashboard
Resource          ../../resources/common.resource
Suite Setup       Open App    /login
Suite Teardown    Close App
Test Setup        Clear Session
Test Tags         auth    guard    ui


*** Test Cases ***
Guest Is Redirected From Every Protected Route
    [Documentation]    ครอบคลุมทุก path ใน router รวม sub-route (/borrow/new, /return/new) และ /notifications
    FOR    ${path}    IN
    ...    /    /equipment/new    /borrow    /borrow/new    /return    /return/new
    ...    /calendar    /reports    /notifications    /settings
        Go To    ${BASE_URL}${path}
        Login Page Should Be Shown
        Get Element Count    css=[data-testid="app-sidebar"]    ==    0
    END
    Capture Page    85-guard-guest-redirect

Logged In User Opening Login Is Sent To Dashboard
    [Documentation]    ล็อกอินแล้วเปิด /login ซ้ำ → เด้งกลับหน้า Dashboard ไม่ต้องล็อกอินใหม่
    Login Through UI
    Go To    ${BASE_URL}/login
    Dashboard Should Be Loaded
    Get Url    ==    ${BASE_URL}/

Session Survives Page Reload
    [Documentation]    token เก็บใน sessionStorage — reload หน้าแล้วยังอยู่หน้าเดิม
    Login Through UI
    Go To    ${BASE_URL}/reports
    Wait For Elements State    ${EQ_LIST}    visible    timeout=20s
    Reload
    Wait For Elements State    ${EQ_LIST}    visible    timeout=20s
    Get Url    ==    ${BASE_URL}/reports

Protected Page Is Blocked Again After Logout
    [Documentation]    ออกจากระบบแล้วกด back / เปิด URL เดิม → ต้องกลับไปหน้า login
    Login Through UI
    Go To    ${BASE_URL}/calendar
    Wait For Elements State    css=[data-testid="calendar-page"]    visible    timeout=20s
    Logout
    Login Page Should Be Shown
    Go Back
    Login Page Should Be Shown
    Go To    ${BASE_URL}/calendar
    Login Page Should Be Shown
