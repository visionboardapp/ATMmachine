protocol UserData {
  var userName: String { get }           //Имя пользователя
  var userCardId: String { get }         //Номер карты
  var userCardPin: Int { get }           //Пин-код
  var userCash: Float { get set}         //Наличные пользователя
  var userBankDeposit: Float { get set}  //Банковский депозит
  var userPhone: String { get }          //Номер телефона
  var userPhoneBalance: Float { get set} //Баланс телефона
}

struct User: UserData {
    var userName: String
    var userCardId: String
    var userCardPin: Int
    var userCash: Float
    var userBankDeposit: Float
    var userPhone: String
    var userPhoneBalance: Float
}

enum TextErrors: String {
    case wrongUser = "Не удалость войти в аккаунт"
    case notEnoughDepositMoney = "У вас на счете недостаточно денег"
    case internalError = "Сервис не доступен"
    case wrongCellNumber = "Вы ввели неправильный номер телефона"
    case notEnoughtCash = "У вас не хватает наличных"
}

enum DescriptionTypesAvailableOperations: String {
    case checkBalance
    case withdrawCash
    case makeDeposit
    case payCellPhoneBill
}

enum UserAction {
    case checkBalance
    case withdrawCash(amount: Float)
    case makeDeposit(amount: Float)
    case payCellPhone(phoneNumber: String, method: PaymentMethod, amount: Float)
}

enum PaymentMethod {
    case cash
    case transfer
}

class ATM {
  private let userCardId: String
  private let userCardPin: Int
  private var someBank: BankApi
  private let action: UserAction
 
  init(
    userCardId: String,
    userCardPin: Int,
    someBank: BankApi,
    action: UserAction
  ) {
    self.userCardId = userCardId
    self.userCardPin = userCardPin
    self.someBank = someBank
    self.action = action
 
    sendUserDataToBank(userCardId: userCardId, userCardPin: userCardPin, action: action)
  }
 
  public final func sendUserDataToBank(userCardId: String, userCardPin: Int, action: UserAction) {
    if someBank.checkCurrentUser(userCardId: userCardId, userCardPin: userCardPin) {
        switch action {
        case .checkBalance:
            someBank.showUserBalance()
        case let .makeDeposit(amount: amount):
            someBank.showTopUpAccount(cash: amount)
            if someBank.checkMaxUserCash(cash: amount) {
                someBank.putCashDeposit(topUp: amount)
            } else {
                someBank.showError(error: .notEnoughtCash)
            }
        case let .payCellPhone(phoneNumber: phoneNumber, method: method, amount: amount):
            if someBank.checkUserPhone(phone: phoneNumber) {
                switch method {
                case .cash:
                    someBank.showUserToppedUpMobilePhoneCash(cash: amount)
                    if someBank.checkMaxUserCash(cash: amount) {
                        someBank.topUpPhoneBalanceCash(pay: amount)
                    } else {
                        someBank.showError(error: .notEnoughtCash)
                    }
                case .transfer:
                    someBank.showUserToppedUpMobilePhoneDeposit(deposit: amount)
                    if someBank.checkMaxAccountDeposit(withdraw: amount) {
                        someBank.topUpPhoneBalanceDeposit(pay: amount)
                    } else {
                        someBank.showError(error: .notEnoughDepositMoney)
                    }
                 
                }
            } else {
                someBank.showError(error: .wrongCellNumber)
            }
            
        case let .withdrawCash(amount: amount):
            someBank.showWithdrawalDeposit(cash: amount)
            if someBank.checkMaxAccountDeposit(withdraw: amount) {
                someBank.getCashFromDeposit(cash: amount)
            } else {
                someBank.showError(error: .notEnoughDepositMoney)
            }
        }
    } else {
        someBank.showError(error: .wrongUser)
    }
  }
}

protocol BankApi {
  func showUserBalance()
  func showUserToppedUpMobilePhoneCash(cash: Float)
  func showUserToppedUpMobilePhoneDeposit(deposit: Float)
  func showWithdrawalDeposit(cash: Float)
  func showTopUpAccount(cash: Float)
  func showError(error: TextErrors)

  func checkUserPhone(phone: String) -> Bool
  func checkMaxUserCash(cash: Float) -> Bool
  func checkMaxAccountDeposit(withdraw: Float) -> Bool
  func checkCurrentUser(userCardId: String, userCardPin: Int) -> Bool
 
  mutating func topUpPhoneBalanceCash(pay: Float)
  mutating func topUpPhoneBalanceDeposit(pay: Float)
  mutating func getCashFromDeposit(cash: Float)
  mutating func putCashDeposit(topUp: Float)
}

struct BankClient: BankApi {
    var user: UserData
    
    func showUserBalance() {
        print("Здравствуйте,\(user.userName), ваш баланс $\(user.userBankDeposit)")
    }
    
    func showUserToppedUpMobilePhoneCash(cash: Float) {
        print("Вы собираетесь пополнить баланс вашего телефо на $\(cash) наличными")
    }
    
    func showUserToppedUpMobilePhoneDeposit(deposit: Float) {
        print("Вы собираетесь пополнить баланс вашего телефо на $\(deposit) с вашего банковского счета")
    }
    
    func showWithdrawalDeposit(cash: Float) {
        print("Вы собираетесь снять $\(cash) с вашего банковского счета")
    }
    
    func showTopUpAccount(cash: Float) {
        print("Вы собираетесь положить $\(cash) на ваш банковский счета")
    }
    
    func showError(error: TextErrors) {
        print("Извините за неудобства, произошла ошибка. \(error.rawValue). Повторите попытку")
    }
    
    func checkUserPhone(phone: String) -> Bool {
        return user.userPhone == phone
    }
    
    func checkMaxUserCash(cash: Float) -> Bool {
        return user.userCash >= cash
    }
    
    func checkMaxAccountDeposit(withdraw: Float) -> Bool {
        return user.userBankDeposit >= withdraw
    }
    
    func checkCurrentUser(userCardId: String, userCardPin: Int) -> Bool {
        return user.userCardId == userCardId && user.userCardPin == userCardPin
    }
    
    mutating func topUpPhoneBalanceCash(pay: Float) {
        user.userCash -= pay
        user.userPhoneBalance += pay
    }
    
    mutating func topUpPhoneBalanceDeposit(pay: Float) {
        user.userBankDeposit -= pay
        user.userPhoneBalance += pay
    }
    
    mutating func getCashFromDeposit(cash: Float) {
        user.userBankDeposit -= cash
        user.userCash += cash
    }
    
    mutating func putCashDeposit(topUp: Float) {
        user.userCash -= topUp
        user.userBankDeposit += topUp
    }
}



let user = User(
    userName: "Olga",
    userCardId: "179971",
    userCardPin: 3335,
    userCash: 200,
    userBankDeposit: 600,
    userPhone: "111-111-1111",
    userPhoneBalance: 30
)

let bankClient = BankClient(user: user)

let atm1 = ATM(userCardId: "179971", userCardPin: 3335, someBank: bankClient, action: .checkBalance)
let atm2 = ATM(userCardId: "179971", userCardPin: 3336, someBank: bankClient, action: .checkBalance)
let atm3 = ATM(userCardId: "17971", userCardPin: 3335, someBank: bankClient, action: .checkBalance)
let atm4 = ATM(userCardId: "179971", userCardPin: 3335, someBank: bankClient, action: .withdrawCash(amount: 200))
let atm5 = ATM(userCardId: "179971", userCardPin: 3335, someBank: bankClient, action: .withdrawCash(amount: 800))
let atm6 = ATM(userCardId: "179971", userCardPin: 3335, someBank: bankClient, action: .payCellPhone(phoneNumber: "111-111-1111", method: .cash, amount: 100))
let atm7 = ATM(userCardId: "179971", userCardPin: 3335, someBank: bankClient, action: .payCellPhone(phoneNumber: "111-111-1111", method: .cash, amount: 300))
let atm8 = ATM(userCardId: "179971", userCardPin: 3335, someBank: bankClient, action: .payCellPhone(phoneNumber: "111-111-1111", method: .cash, amount: 100))
