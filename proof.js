const fetch = require('node-fetch');

// TODO: Fill in with custom proof generation API and uncomment line in updateBlockHeader.js
async function fetchProofData(url, data) {
    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                // 'Authorization': 'Bearer your-token' (if needed)
            },
            body: JSON.stringify(data)
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        } else {
            const jsonResponse = await response.json();
            return jsonResponse;
        }
    } catch (error) {
        console.error('Error:', error);
    }
}

// Sample usage
const API_ENDPOINT = 'https://example.com/api/endpoint';
const postData = {
    key1: 'value1',
    key2: 'value2',
};

fetchProofData(API_ENDPOINT, postData)
    .then(responseData => console.log(responseData));
