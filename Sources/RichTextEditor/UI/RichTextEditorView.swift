//
//  SectionTextEditorView.swift
//  FreshBooks
//
//  Created by Dion Durigon on 2020-12-02.
//  Copyright © 2020 FreshBooks. All rights reserved.
//

import UIKit

protocol RichTextEditorViewDelegate: class {
    func didTapDeleteSectionButton(sender: RichTextEditorView)
}

protocol RichTextEditorViewModelType {
    var title: String? { get set }

    /// Defines the character limit of the title when the user is able to edit/enter it
    var titleCharacterLimit: Int { get set }

    /// Defines the colour of the text in the title.
    var titleColor: UIColor { get set }

    /// Defines the font for the title
    var titleFont: UIFont { get set }

    /// Defines the font size for the body - The font itself will be the default system font.
    var bodyFont: UIFont { get set }

    /// HTML Body.
    var html: String? { get set }

    /// Body placeholder
    var placeholder: String? { get set }

    /// Should this Text View have a Delete button?
    var showDeleteButton: Bool { get set }
}

class RichTextEditorView: UIView {

    var sampleHTML: String?
    weak var delegate: RichTextEditorViewDelegate?
    var viewModel: RichTextEditorViewModelType?

    var readOnly: Bool = false
    
    fileprivate(set) lazy var formatBar: FormatBar = {
        return self.createToolbar()
    }()
    
    private var richTextView: TextView {
        get {
            return editorView.richTextView
        }
    }
    
    fileprivate(set) lazy var editorView: EditorView = {
        let defaultHTMLFont: UIFont

        defaultHTMLFont = UIFontMetrics.default.scaledFont(for: Constants.defaultContentFont)
        
        let editorView = EditorView(
            defaultFont: Constants.defaultContentFont,
            defaultHTMLFont: defaultHTMLFont,
            defaultParagraphStyle: .default,
            defaultMissingImage: Constants.defaultMissingImage)

        editorView.clipsToBounds = false
        setupRichTextView(editorView.richTextView)
        
        return editorView
    }()
    
    private let titleField: UITextField  = {
        let textField = UITextField(frame: CGRect.zero)
        return textField
    }()
    
    private func setupRichTextView(_ textView: TextView) {
//        let accessibilityLabel = NSLocalizedString("Rich Content", comment: "Post Rich content")
        
        textView.isEditable = readOnly
        textView.delegate = self
        textView.formattingDelegate = self
        textView.textAttachmentDelegate = self
        textView.accessibilityIdentifier = "richContentView"
        textView.clipsToBounds = false
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
    }
    
    private func configureConstraints() {
        let layoutGuide = self.readableContentGuide
        
        titleField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleField.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor),
            titleField.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor),
            titleField.topAnchor.constraint(equalTo: self.topAnchor, constant: 0)
            ])
        
        NSLayoutConstraint.activate([
            editorView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor),
            editorView.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor),
            editorView.topAnchor.constraint(equalTo: titleField.bottomAnchor, constant: 10),
            editorView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0)
            ])
    }
    
    private func registerAttachmentImageProviders() {
        let providers: [TextViewAttachmentImageProvider] = [
            CommentAttachmentRenderer(font: Constants.defaultContentFont),
            HTMLAttachmentRenderer(font: Constants.defaultHtmlFont),
        ]

        for provider in providers {
            richTextView.registerAttachmentImageProvider(provider)
        }
    }
    
    override init(frame: CGRect) {
        self.readOnly = false
        super.init(frame: frame)
        
        baseInit()
    }

    required init?(coder aDecoder: NSCoder) {
        self.readOnly = false
        super.init(coder: aDecoder)
        
        baseInit()
    }

    init(html: String?) {
        self.sampleHTML = html
        self.readOnly = false
        super.init(frame: CGRect.zero)
        
        baseInit()
    }
    
    init(viewModel: RichTextEditorViewModelType?, readOnly: Bool = false) {
        self.readOnly = readOnly
        self.viewModel = viewModel
        self.sampleHTML = viewModel?.html
        
        super.init(frame: CGRect.zero)
        
        baseInit()
    }
    
    func baseInit() {
        
        editorView.richTextView.textContainer.lineFragmentPadding = 0
        
        if #available(iOS 13.0, *) {
            self.backgroundColor = UIColor.systemBackground
            editorView.richTextView.textColor = UIColor.label
        } else {
            // Fallback on earlier versions
        }
        
        titleField.delegate = self
        titleField.returnKeyType = .done
        
        editorView.frame = bounds
        editorView.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        editorView.isScrollEnabled = false
        
//        registerAttachmentImageProviders()
        
        if readOnly {
            editorView.richTextView.isEditable = false
            editorView.richTextView.isSelectable = false
            editorView.richTextView.isUserInteractionEnabled = false
            
            titleField.isUserInteractionEnabled = false
        } else {
            editorView.richTextView.isEditable = true
            editorView.richTextView.isSelectable = true
            editorView.richTextView.isUserInteractionEnabled = true
            
            titleField.isUserInteractionEnabled = true
        }
        
        self.addSubview(titleField)
        self.addSubview(editorView)
        
        configureConstraints()
    
        updateFromViewModel()
        
        if !readOnly {
            editorView.becomeFirstResponder()
                    
            let nc = NotificationCenter.default
            nc.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil) { notification in
                self.keyboardWillShow(notification as NSNotification)
            }
            
            nc.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil) { notification in
                self.keyboardWillHide(notification as NSNotification)
            }
        }
        
    }
    
    func updateFromViewModel() {
        guard let viewModel = viewModel, let html = viewModel.html else { return }
       
        editorView.setHTML(html)
        titleField.text = viewModel.title ?? ""
        titleField.font = viewModel.bodyFont
        titleField.textColor = viewModel.titleColor
    }
    
    // MARK: - Toolbar
    
    func makeToolbarButton(identifier: FormattingIdentifier) -> FormatBarItem {
        let button = FormatBarItem(image: identifier.iconImage, identifier: identifier.rawValue)
//        button.accessibilityLabel = identifier.accessibilityLabel
//        button.accessibilityIdentifier = identifier.accessibilityIdentifier
        return button
    }
    
    func createToolbar() -> FormatBar {
        let toolbarItems = itemsForToolbar

        let toolbar = FormatBar()
        toolbar.tintColor = .gray
        toolbar.highlightedTintColor = .blue
        toolbar.selectedTintColor = self.tintColor
        toolbar.disabledTintColor = .lightGray
        toolbar.dividerTintColor = .gray

        toolbar.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: 44.0)
        toolbar.autoresizingMask = [ .flexibleHeight ]
        toolbar.formatter = self

        toolbar.setDefaultItems(toolbarItems)
        
        toolbar.barItemHandler = { [weak self] item in
            self?.handleAction(for: item)
        }

        return toolbar
    }
    
    var itemsForToolbar: [FormatBarItem] {
        
//        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
//        done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: nil)
        
        return [
            makeToolbarButton(identifier: .bold),
            makeToolbarButton(identifier: .italic),
            makeToolbarButton(identifier: .underline),
            makeToolbarButton(identifier: .strikethrough),
            makeToolbarButton(identifier: .unorderedlist),
            makeToolbarButton(identifier: .orderedlist),
            makeToolbarButton(identifier: .done)
        ]
    }
    
    func updateFormatBar() {
        guard let toolbar = richTextView.inputAccessoryView as? FormatBar else {
            return
        }

        let identifiers: Set<FormattingIdentifier>
        if richTextView.selectedRange.length > 0 {
            identifiers = richTextView.formattingIdentifiersSpanningRange(richTextView.selectedRange)
        } else {
            identifiers = richTextView.formattingIdentifiersForTypingAttributes()
        }

        toolbar.selectItemsMatchingIdentifiers(identifiers.map({ $0.rawValue }))
    }
    
    // MARK: - Keyboard Handling

    func keyboardWillShow(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo as? [String: AnyObject],
            let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
                return
        }

        refreshInsets(forKeyboardFrame: keyboardFrame)
    }

    func keyboardWillHide(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo as? [String: AnyObject],
            let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
                return
        }

        refreshInsets(forKeyboardFrame: keyboardFrame)
    }
    
    fileprivate func refreshInsets(forKeyboardFrame keyboardFrame: CGRect) {
        
        let localKeyboardOrigin = self.convert(keyboardFrame.origin, from: nil)
        let keyboardInset = max(self.frame.height - localKeyboardOrigin.y, 0)
        
        let contentInset = UIEdgeInsets(
            top: editorView.contentInset.top,
            left: 0,
            bottom: keyboardInset,
            right: 0)

        editorView.contentInset = contentInset
        updateScrollInsets()
    }
    
    func updateScrollInsets() {
        var scrollInsets = editorView.contentInset
        var rightMargin = (self.frame.maxX - editorView.frame.maxX)
        rightMargin -= self.safeAreaInsets.right

        scrollInsets.right = -rightMargin
        editorView.scrollIndicatorInsets = scrollInsets
    }
    
}

// MARK: - Format Bar Delegate

extension RichTextEditorView: FormatBarDelegate {
    func formatBarTouchesBegan(_ formatBar: FormatBar) {
    }

    func formatBar(_ formatBar: FormatBar, didChangeOverflowState state: FormatBarOverflowState) {
        switch state {
        case .hidden:
            print("Format bar collapsed")
        case .visible:
            print("Format bar expanded")
        }
    }
}

// MARK: - Format Bar Actions
extension RichTextEditorView {
    
    func handleAction(for barItem: FormatBarItem) {
        guard let identifier = barItem.identifier,
            let formattingIdentifier = FormattingIdentifier(rawValue: identifier) else {
                return
        }
        
        switch formattingIdentifier {
        case .bold:
            richTextView.toggleBold(range: richTextView.selectedRange)
        case .italic:
            richTextView.toggleItalic(range: richTextView.selectedRange)
        case .underline:
            richTextView.toggleUnderline(range: richTextView.selectedRange)
        case .strikethrough:
            richTextView.toggleStrikethrough(range: richTextView.selectedRange)
        case .unorderedlist:
            richTextView.toggleUnorderedList(range: richTextView.selectedRange)
        case .orderedlist:
            richTextView.toggleOrderedList(range: richTextView.selectedRange)
        case .sourcecode:
            editorView.toggleEditingMode()
        case .done:
            done()
        default:
            break
        }

        updateFormatBar()
    }
    
    func done() {
        viewModel?.html = editorView.getHTML()
        viewModel?.title = titleField.text
    }
}

extension RichTextEditorView: UITextViewDelegate {
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        updateFormatBar()
//        changeRichTextInputView(to: nil)
    }

    func textViewDidChange(_ textView: UITextView) {
        updateFormatBar()
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        switch textView {
        case richTextView:
            formatBar.enabled = true

        default: break
        }
        
        textView.inputAccessoryView = formatBar
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        viewModel?.html = richTextView.getHTML()
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return false
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {

    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return true
    }
}

extension RichTextEditorView: TextViewFormattingDelegate {
    
    func textViewCommandToggledAStyle() {
        
    }
}

extension RichTextEditorView: TextViewAttachmentDelegate {
    
    func downloadImage(from url: URL, success: @escaping (UIImage) -> Void, onFailure failure: @escaping () -> Void) {
        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, _, error) in
            DispatchQueue.main.async {
                guard self != nil else { return }
                guard error == nil, let data = data, let image = UIImage(data: data, scale: UIScreen.main.scale) else {
                    failure()
                    return
                }
                success(image)
            }
        }
        task.resume()
    }
    
    func textView(_ textView: TextView, attachment: NSTextAttachment, imageAt url: URL, onSuccess success: @escaping (UIImage) -> Void, onFailure failure: @escaping () -> Void) {
        
        switch attachment {
        case let imageAttachment as ImageAttachment:
            if let imageURL = imageAttachment.url {
                downloadImage(from: imageURL, success: success, onFailure: failure)
            }
        default:
            failure()
        }
    }
    
    func textView(_ textView: TextView, urlFor imageAttachment: ImageAttachment) -> URL? {
        guard let image = imageAttachment.image else {
            return nil
        }

        return image.saveToTemporaryFile()
    }
    
    func textView(_ textView: TextView, placeholderFor attachment: NSTextAttachment) -> UIImage {
        if #available(iOS 13.0, *) {
            return UIImage(systemName: "photo")!
        } else {
            return UIImage(named: "image")!
        }
    }
    
    func textView(_ textView: TextView, deletedAttachment attachment: MediaAttachment) {
        
    }
    
    func textView(_ textView: TextView, selected attachment: NSTextAttachment, atPosition position: CGPoint) {
//        switch attachment {
//        case let attachment as HTMLAttachment:
//            displayUnknownHtmlEditor(for: attachment, in: textView)
//        case let attachment as MediaAttachment:
//            selected(in: textView, textAttachment: attachment, atPosition: position)
//        default:
//            break
//        }
    }
    
    func textView(_ textView: TextView, deselected attachment: NSTextAttachment, atPosition position: CGPoint) {
//        deselected(in: textView, textAttachment: attachment, atPosition: position)
    }
}

extension RichTextEditorView: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let viewModel = viewModel else { return true }

        let currentText = textField.text ?? ""
        let newLength = currentText.count + string.count - range.length

        return newLength <= viewModel.titleCharacterLimit
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        viewModel?.title = textField.text
        textField.resignFirstResponder()
        return true
    }
}


extension UIImage {

    func saveToTemporaryFile() -> URL {
        let fileName = "\(ProcessInfo.processInfo.globallyUniqueString)_file.jpg"

        guard let data = self.jpegData(compressionQuality: 0.9) else {
            fatalError("Could not conert image to JPEG.")
        }

        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)

        guard (try? data.write(to: fileURL, options: [.atomic])) != nil else {
            fatalError("Could not write the image to disk.")
        }

        return fileURL
    }
}

extension UIView {
    
    static var tintedMissingImage: UIImage = {
        guard let image = UIImage(named: "image") else {
            return UIImage()
        }
        
        return image
    }()
}

extension FormattingIdentifier {

    var iconImage: UIImage {

        switch self {
        case .media:
            return gridicon(.image)
        case .bold:
            return gridicon(.bold)
        case .italic:
            return gridicon(.italic)
        case .underline:
            return gridicon(.underline)
        case .strikethrough:
            return gridicon(.strikethrough)
        case .orderedlist:
            return gridicon(.listOrdered)
        case .unorderedlist:
            return gridicon(.listUnordered)
        case .done:
            return gridicon(.done)
        default:
            return gridicon(.help)
        }
    }
    
    private func gridicon(_ gridiconType: GridiconType) -> UIImage {
        guard let result = UIImage(named: gridiconType.name) else {
            return UIImage()
        }
        return result
    }
}
