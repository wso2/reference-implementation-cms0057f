import axios from "axios";

const apiClient = (url: string) => {
  return axios.create({
    baseURL: url,
  });
};

export default apiClient;
