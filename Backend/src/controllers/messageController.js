const Message = require('../models/Message');
const User = require('../models/User');
const Chat = require('../models/Chat');

// @desc    Get all messages
// @route   GET /api/message/:chatId
// @access  Protected
const allMessages = async (req, res) => {
    try {
        const messages = await Message.find({ chat: req.params.chatId })
            .populate('sender', 'fullName profilePic email')
            .populate('chat');
        res.json(messages);
    } catch (error) {
        res.status(400);
        throw new Error(error.message);
    }
};

// @desc    Create New Message
// @route   POST /api/message
// @access  Protected
const sendMessage = async (req, res) => {
    const { content, chatId, type } = req.body;

    if (!content || !chatId) {
        console.log('Invalid data passed into request');
        return res.sendStatus(400);
    }

    var newMessage = {
        sender: req.user._id,
        content: content,
        chat: chatId,
        type: type || 'text',
    };

    try {
        var message = await Message.create(newMessage);

        message = await message.populate('sender', 'fullName profilePic');
        message = await message.populate('chat');
        message = await User.populate(message, {
            path: 'chat.users',
            select: 'fullName profilePic email',
        });

        await Chat.findByIdAndUpdate(req.parentKey, { latestMessage: message }); // req.parentKey??? No, chatId.

        await Chat.findByIdAndUpdate(chatId, { latestMessage: message });

        res.json(message);
    } catch (error) {
        res.status(400);
        throw new Error(error.message);
    }
};

module.exports = { allMessages, sendMessage };
