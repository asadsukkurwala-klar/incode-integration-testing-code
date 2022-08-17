## TEST
<div hidden>
@startuml
'https://plantuml.com/sequence-diagram

autonumber

actor       User as user
participant    MobileApp    as app #F5c550
participant     "KYC"     as kyc #Aae283
participant     IncodeBridge      as incode #F7a7f5
participant     Incode      as incodeexternal #ccccff
participant     Kafka      as kafka #B1b1ac
user -> app : user begins. \nAssuming verifications have already been created,\nusing the current flow
activate app #F5c550
app  [#red]-> kyc : requestFlowStart(userId).\nHTTP POST /api/v1/kyc/tierVerifications/incode/start\n{"userId": userId}
activate kyc #Aae283
kyc   [#green]-> kyc : saveFlowState(userId).
kyc [#green]-> incode : startOnboarding(userId: userId).\nHTTP POST /api/v1/incode-bridge/onboarding/start\n{"userId": userId}
activate incode #F7a7f5
incode [#purple]-> incodeexternal : startOnboarding(externalId: userId).\nHTTP POST /omni/start\n{"uuid": userId}
activate incodeexternal #ccccff
incodeexternal [#cccfff]-> incode : response: {token, interviewId...}
deactivate incodeexternal
incode [#purple]-> kyc : response: {token, interviewId}.
deactivate incode
kyc [#green]-> app : response: {token, interviewId}
deactivate app
deactivate kyc
user <-> app : user goes through the flow
activate user
activate app #F5c550
app [#red]-> incodeexternal : completeOnboarding(token)
deactivate user
deactivate app
activate incodeexternal #ccccff
incodeexternal [#ccccff]-> incode : callWebhook(uniqueId).\nHTTP POST /incode-bridge/webhook/onboarding\n
activate kyc #Aae283
activate incode #F7a7f5
incode [#purple]-> incodeexternal : fetchOnboardingData(token) \n ocr/images.\nHTTP GET /omni/get/ocr-data\n  X-Hardware-Id: {token}\n  X-Api-Key: {client_id}\nHTTP GET /omni/get/images\n  X-Hardware-Id: {token}\n  X-Api-Key: {client_id}
deactivate incodeexternal

deactivate incode
kyc [#green]-> kafka : generateEvent(VerifyIdentificationResult)
deactivate kyc
activate kafka #B1b1ac
kyc <[#DCCE42]-> kafka : handleEvent(VerifyIdentificationResult)
deactivate kafka
activate kyc #DCCE42
deactivate kyc
@enduml
</div>
![](firstDiagram.svg)