use std::f64::consts::PI;
use sha2::{Sha256, Digest};


pub fn generateCarrier(sampling_frequency: u32, carrier_frequency: f64, init_phy: f64, point_number: u64) -> Vec<f64> {
    let f = 1.0 / sampling_frequency as f64;
    let mut wave: Vec<f64> = vec![];
    for i in 0..point_number {
        let t = i as f64 * f;
        let value = (2.0 * PI * ((carrier_frequency * t) + init_phy)).sin();
        wave.push(value);
    }
    wave
}

pub fn toBit(wav_data: Vec<f32>, bit_ext_point_num: u16, sampling_frequency: u32, carrier_frequency: f64, init_phy: f64) -> Vec<u8> {
    let point_number: u64 = wav_data.len() as u64;

    let carrier_wave = generateCarrier(sampling_frequency, carrier_frequency, init_phy, point_number);

    let mut demodulated_wav = vec![];
    for (psk, cw_p) in wav_data.iter().zip(carrier_wave.iter()) {
        demodulated_wav.push((*cw_p as f32) * (*psk));
    }

    let mut hard_bits= vec![];
    for i in (0..demodulated_wav.len()).step_by(bit_ext_point_num as usize) {
        let sum = demodulated_wav[i..i + bit_ext_point_num as usize].iter().sum::<f32>();
        if sum > 0.0 {
            hard_bits.push(1_u8);
        } else {
            hard_bits.push(0_u8);
        }
    }

    let mut data_byte = vec![];
    for i in (0..hard_bits.len()).step_by(8) {
        let mut byte = 0_u8;
        for j in 0..8 {
            byte |= hard_bits[i + j] << j;
        }
        data_byte.push(byte);
    }

    data_byte
}

pub struct FileInfo {
    pub file_name: String,
    pub hash_value: String,
    pub check_value: String,
    pub data: Vec<u8>,
}

pub fn getFileInfo(data_byte: Vec<u8>) -> FileInfo {
    let mut si: usize = usize::MAX;
    let mut ei: usize = usize::MAX;
    for i in 0..data_byte.len() {
        let s = String::from_utf8(data_byte[i..i + 10].to_vec()).expect("Failed to convert bytes to string");
        let e = String::from_utf8(data_byte[i..i + 15].to_vec()).expect("Failed to convert bytes to string");

        if s == "File info:" && si == usize::MAX {
            si = i;
        }

        if e == ".End file info." && ei == usize::MAX {
            ei = i;
        }

        if si != usize::MAX && ei != usize::MAX {
            break;
        }
    }

    let file_info = String::from_utf8(data_byte[si + 10..ei].to_vec()).expect("Failed to convert bytes to string");
    let info_p = file_info.split(',').collect::<Vec<&str>>();
    let file_name = info_p[0];
    let file_size = usize::from_str_radix(info_p[1], 10).expect("Failed to parse file size");
    let hash_value = info_p[2].to_string();
    let data = data_byte[ei + 15..ei + 14 + file_size].to_vec();
    let md5_checker = String::from_utf8(Sha256::digest(data.clone()).to_ascii_lowercase()).expect("Failed to convert hash to string");



    FileInfo {
        file_name: file_name.to_string(),
        hash_value,
        check_value: md5_checker,
        data: data,
    }
}