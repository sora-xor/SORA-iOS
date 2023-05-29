protocol AccountConfirmViewProtocol: ControllerBackedProtocol {
    func didReceive(words: [String], afterConfirmationFail: Bool)
}

protocol AccountConfirmPresenterProtocol: AnyObject {
    func setup()
    func requestWords()
    func confirm(words: [String])
    func skip()
}

protocol AccountConfirmInteractorInputProtocol: AnyObject {
    func requestWords()
    func confirm(words: [String])
    func skipConfirmation()
}

protocol AccountConfirmInteractorOutputProtocol: AnyObject {
    func didReceive(words: [String], afterConfirmationFail: Bool)
    func didCompleteConfirmation()
    func didReceive(error: Swift.Error)
}

protocol AccountConfirmWireframeProtocol: AlertPresentable, ErrorPresentable {
    func proceed(from view: AccountConfirmViewProtocol?)
}
