/*
 MIT License

 Copyright (c) 2017-2018 MessageKit

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import UIKit
import AVFoundation

/// A subclass of `MessageContentCell` used to display video and audio messages.
open class AudioMessageCell: MessageContentCell {

    /// The `ImageName` enum holds the names od default iamges used to decorate play button
    public enum ImageName: String {
        case play
        case pause
    }

    /// The play button view to display on audio messages.
    open lazy var playButton: UIButton = {
        let playButton = UIButton(type: .custom)
        let playImage = AudioMessageCell.getImageWithName(.play)
        let pauseImage = AudioMessageCell.getImageWithName(.pause)
        playButton.setImage(playImage?.withRenderingMode(.alwaysTemplate), for: .normal)
        playButton.setImage(pauseImage?.withRenderingMode(.alwaysTemplate), for: .selected)
        return playButton
    }()

    /// The time duration lable to display on audio messages.
    open lazy var durationLabel: UILabel = {
        let durationLabel = UILabel(frame: CGRect.zero)
        durationLabel.textAlignment = .right
        durationLabel.font = UIFont.systemFont(ofSize: 14)
        durationLabel.text = "0:00"
        return durationLabel
    }()

    open lazy var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.progress = 0.0
        return progressView
    }()
    
    open lazy var avatarImageView:UIImageView = {
        let image = UIImageView()
        image.layer.cornerRadius = 20
        image.layer.masksToBounds = true
        image.backgroundColor = .white
        return image
        
    }()
    
    private var incomingConstraint:[NSLayoutConstraint] = []
    private var outgoingConstraint:[NSLayoutConstraint] = []


    // MARK: - Methods

    /// Responsible for setting up the constraints of the cell's subviews.
    open func setupConstraints() {
        
        avatarImageView.constraint(equalTo: CGSize(width: 40, height: 40))
        
        let avatarImageViewLeftAnchor = avatarImageView.leftAnchor.constraint(equalTo: messageContainerView.leftAnchor,constant:10)
        
        
        let avatarImageViewRightAnchor = avatarImageView.rightAnchor.constraint(equalTo: messageContainerView.rightAnchor,constant:-10)
        
        avatarImageView.addConstraints(centerY: messageContainerView.centerYAnchor)

        playButton.constraint(equalTo: CGSize(width: 25, height: 25))
        
        let playButtonTemp1LeftAnchor = playButton.leftAnchor.constraint(equalTo: avatarImageView.rightAnchor,constant:5)
        
        let payButtonTemp2LeftAnchor = playButton.leftAnchor.constraint(equalTo: messageContainerView.leftAnchor,constant:10)
        
        playButton.addConstraints(centerY: messageContainerView.centerYAnchor)
        
        let durationLabelTemp1RightAnchor = durationLabel.rightAnchor.constraint(equalTo: avatarImageView.leftAnchor,constant:-5)
        
        let durationLabelTemp2RightAnchor = durationLabel.rightAnchor.constraint(equalTo: messageContainerView.rightAnchor,constant:-10)
        
        durationLabel.addConstraints(centerY: messageContainerView.centerYAnchor)

        progressView.addConstraints(left: playButton.rightAnchor,
                                    right: durationLabel.leftAnchor,
                                    centerY: messageContainerView.centerYAnchor,
                                    leftConstant: 5,
                                    rightConstant: 5)
        
        // active custom constraint //
        outgoingConstraint = [avatarImageViewLeftAnchor,
                              playButtonTemp1LeftAnchor,
                              durationLabelTemp2RightAnchor]
        
        incomingConstraint = [avatarImageViewRightAnchor,
                              payButtonTemp2LeftAnchor,
                              durationLabelTemp1RightAnchor]

    }
    
    open override func setupSubviews() {
        super.setupSubviews()

        messageContainerView.addSubview(avatarImageView)
        messageContainerView.addSubview(playButton)
        messageContainerView.addSubview(durationLabel)
        messageContainerView.addSubview(progressView)
        setupConstraints()
    }

    open override func prepareForReuse() {
        super.prepareForReuse()
        progressView.progress = 0
        playButton.isSelected = false
        durationLabel.text = "0:00"
    }

    open class func getImageWithName(_ imageName: ImageName) -> UIImage? {
        let assetBundle = Bundle.messageKitAssetBundle()
        let imagePath = assetBundle.path(forResource: imageName.rawValue, ofType: "png", inDirectory: "Images")
        let image = UIImage(contentsOfFile: imagePath ?? "")
        return image
    }

    /// Handle tap gesture on contentView and its subviews.
    open override func handleTapGesture(_ gesture: UIGestureRecognizer) {
        let touchLocation = gesture.location(in: self)
        // compute play button touch area, currently play button size is (25, 25) which is hardly touchable
        // add 10 px around current button frame and test the touch against this new frame
        let playButtonTouchArea = CGRect(playButton.frame.origin.x - 10.0, playButton.frame.origin.y - 10, playButton.frame.size.width + 20, playButton.frame.size.height + 20)
        let translateTouchLocation = convert(touchLocation, to: messageContainerView)
        if playButtonTouchArea.contains(translateTouchLocation) {
            delegate?.didTapPlayButton(in: self)
        } else {
            super.handleTapGesture(gesture)
        }
    }

    // MARK: - Configure Cell

    open override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
        configureCellApperance(with: message, indexPath: indexPath, messagesCollectionView: messagesCollectionView)
        
        guard let displayDelegate = messagesCollectionView.messagesDisplayDelegate else {
            fatalError(MessageKitError.nilMessagesDisplayDelegate)
        }
        // default implementation for decorate cell
        guard case let .audio(audioItem) = message.kind else { fatalError("Failed decorate audio cell") }
        durationLabel.text = displayDelegate.audioProgressTextFormat(audioItem.duration, for: self, in: messagesCollectionView)
        
        displayDelegate.avatarImageViewForAudioCell(avatarImageView, for: self, at: indexPath, in: messagesCollectionView)
        
        
        progressView.progress = 0.0
        playButton.isSelected = false
        // call configure delegate for fourther config
        displayDelegate.configureAudioCell(self, message: message)
    }

    private func configureCellApperance(with message: MessageType, indexPath: IndexPath, messagesCollectionView: MessagesCollectionView) {
        // modify elements constrains based on message direction (incoming or outgoing)
        guard let dataSource = messagesCollectionView.messagesDataSource else {
            fatalError(MessageKitError.nilMessagesDataSource)
        }

        let isIncommingMessage = !dataSource.isFromCurrentSender(message: message)
        self.updateConstraint(isIncommingMessage:isIncommingMessage)

        guard let displayDelegate = messagesCollectionView.messagesDisplayDelegate else {
            fatalError(MessageKitError.nilMessagesDisplayDelegate)
        }
        let tintColor = displayDelegate.audioTintColor(for: message, at: indexPath, in: messagesCollectionView)
        playButton.imageView?.tintColor = tintColor
        durationLabel.textColor = tintColor
        progressView.tintColor = tintColor
    }
    
    
    //MARK: - helpers
    
    private func updateConstraint(isIncommingMessage:Bool){
        
        for constraint in self.incomingConstraint{
            constraint.priority = isIncommingMessage ? UILayoutPriority(725) :  UILayoutPriority(225)
            
            constraint.isActive = true
        }
        
        for constraint in self.outgoingConstraint{
            constraint.priority = isIncommingMessage ? UILayoutPriority(225) :  UILayoutPriority(725)
            constraint.isActive = true

        }
        
        self.layoutIfNeeded()
    }

}
