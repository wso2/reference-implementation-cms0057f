import React from 'react';
import '../assets/styles/appointment.css';

interface MessageBoxProps {
    message: string;
    type: 'success' | 'error' | 'warning';
    onClose: () => void;
}

const MessageBox: React.FC<MessageBoxProps> = ({ message, onClose }) => {
    return (
        <div className={`message-box`}>
            <p>{message}</p>
            <button onClick={onClose} className="close-btn">Close</button>
        </div>
    );
};

export default MessageBox;