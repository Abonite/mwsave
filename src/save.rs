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

pub fn toWav(file_name: &str, source_data: Vec<u8>, bit_ext_point_num: u16, sampling_frequency: u32, carrier_frequency: f64, init_phy: f64) -> Vec<f32> {
    let md5_checker = Sha256::digest(source_data.clone()).to_vec();
    let md5_checker = md5_checker.iter().map(|b| format!("{:02x}", b)).collect::<String>();

    let mut final_data = Vec::from(format!("File info:{},{},{}.End file info.", file_name, source_data.len(), md5_checker));
    final_data.extend(source_data);
    let point_number = final_data.len() as u64 * bit_ext_point_num as u64 * 8;

    let carrier_wave = generateCarrier(sampling_frequency, carrier_frequency, init_phy, point_number);

    let mut unmodulated_bit = vec![];
    let ones = vec![1_i8; bit_ext_point_num as usize];
    let zeros = vec![-1_i8; bit_ext_point_num as usize];
    for byte in final_data {
        for i in 0..8 {
            let bit = (byte >> i) & 1;
            if bit == 1 {
                unmodulated_bit.extend(ones.clone());
            } else {
                unmodulated_bit.extend(zeros.clone());
            }
        }
    }

    let mut modulated_wave = vec![];
    for (bit, cw_p) in unmodulated_bit.iter().zip(carrier_wave.iter()) {
        modulated_wave.push((*cw_p as f32) * (*bit as f32));
    }

    modulated_wave
}