*** Settings ***
Documentation     Smoke test — หน้าเว็บโหลดได้ และ route ที่ต้องล็อกอินถูกป้องกันไว้
Resource          ../../resources/common.resource
Suite Setup       Open App    /login
Suite Teardown    Close App
Test Tags         smoke    ui


*** Test Cases ***
App Loads With Correct Title
    Get Title    ==    Rent & Borrow

Guest Is Redirected To Login
    [Documentation]    ยังไม่ล็อกอินแล้วเข้าหน้าแรก → ถูกเด้งไป /login
    Go To    ${BASE_URL}/
    Wait For Elements State    ${LOGIN_SUBMIT}    visible    timeout=15s
    Get Url    ==    ${LOGIN_URL}

Guest Cannot Open Protected Pages
    [Documentation]    ทุก route ที่อยู่หลัง guard ต้องเด้งกลับ /login
    FOR    ${path}    IN    /equipment/new    /borrow    /return    /calendar    /reports    /settings
        Go To    ${BASE_URL}${path}
        Wait For Elements State    ${LOGIN_SUBMIT}    visible    timeout=15s
        Get Url    ==    ${LOGIN_URL}
    END

Take Screenshot Of Login
    Capture Page    00-smoke-login
