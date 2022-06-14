*** Settings ***
Documentation       Order robots from RobotSpareBin Industries Inc.
...                 Save order HTML receipt as PDF
...                 Save screenshot of ordered robot
...                 Embeds sceenshot of the robot to PDF receipt
...                 Create zip archive of receipts and images

Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.Browser.Selenium
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault

*** Tasks ***
Order robots from RobotSpareBin
    Download csv file
    Open order website and fill data
    Create ZIP


*** Keywords ***
  
    
Download csv file
    Add heading    Provide csv file link:     #https://robotsparebinindustries.com/orders.csv
    Add text input    link    link
    ${result}=    Run dialog
    Download    ${result.link}    overwrite=True

Fill and submit one order
    [Arguments]    ${order}

    Select From List By Value    id:head    ${order}[Head]
    Select Radio Button    group_name=body    value=${order}[Body]
    Input Text    class:form-control    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    Preview
    Wait Until Keyword Succeeds    3x    3s    Screenshot
    ...    id:robot-preview-image
    ...    ${OUTPUT_DIR}${/}robot_preview${${order}[Order number]}.png
    Click Button    Order

    TRY
        Export PDF    ${order}
    EXCEPT
        Wait Until Keyword Succeeds    10 times    1 s    Click Button    Order
    FINALLY
        TRY
            Export PDF    ${order}
        EXCEPT
            Wait Until Keyword Succeeds    10 times    1 s    Click Button    Order
        FINALLY
            TRY
                Export PDF    ${order}
            EXCEPT
                Wait Until Keyword Succeeds    10 times    1 s    Click Button    Order
            FINALLY
                Export PDF    ${order}
            END
        END
    END

    Add screenshot to PDF    ${order}
    Click Button    Order another robot

Export PDF
    [Arguments]    ${order}

    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}receipt${${order}[Order number]}.pdf

Add screenshot to PDF
    [Arguments]    ${order}
    @{imgs}=    Create List    ${OUTPUT_DIR}${/}robot_preview${${order}[Order number]}.png
    Open Pdf    ${OUTPUT_DIR}${/}receipt${${order}[Order number]}.pdf
    Add Files To Pdf    ${imgs}    ${OUTPUT_DIR}${/}receipt${${order}[Order number]}.pdf    True
    Close Pdf

Open order website and fill data
    ${secret}=    Get Secret    url
    Open Available Browser   ${secret}[url]     #https://robotsparebinindustries.com/#/robot-order

    ${orders}=    Read table from CSV    orders.csv    header=True

    FOR    ${order}    IN    @{orders}
        Wait Until Element Is Visible    css:Button.btn-dark
        Click Button    OK
        Fill and submit one order    ${order}
    END

Create ZIP
    Archive Folder With Zip    ${OUTPUT_DIR}    ${OUTPUT_DIR}${/}receipts.zip    include=*.pdf
