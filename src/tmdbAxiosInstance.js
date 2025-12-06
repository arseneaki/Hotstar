import axios from "axios";

const tmdbAxiosInstance = axios.create({
    baseURL: process.env.REACT_APP_TMDB_BASE_URL || "https://api.themoviedb.org/3",
    timeout: 10000, // 10 seconds timeout
    headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json'
    }
});

// Request interceptor
tmdbAxiosInstance.interceptors.request.use(
    (config) => {
        return config;
    },
    (error) => {
        return Promise.reject(error);
    }
);

// Response interceptor
tmdbAxiosInstance.interceptors.response.use(
    (response) => response,
    (error) => {
        if (error.response) {
            console.error('API Error:', error.response.status, error.response.data);
        } else if (error.request) {
            console.error('Network Error:', error.request);
        } else {
            console.error('Error:', error.message);
        }
        return Promise.reject(error);
    }
);

export default tmdbAxiosInstance;