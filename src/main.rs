mod save;
mod load;

use std::{fs::File, io::{Read, Write}, path::{Path, PathBuf}, ffi::OsString};
use clap::{CommandFactory, Parser, ValueEnum, Subcommand, error::ErrorKind};
use hound::{WavSpec, SampleFormat};
use save::*;
use load::*;


#[derive(Parser)]
#[command(author="Abonite")]
#[command(version="0.1.1")]
#[command(about="Encode the file into an audio file so you can record it on tape.")]
struct Cli {
    #[command(subcommand)]
    mode: Mode,

    #[arg(long, short='s', default_value="44100")]
    sampling_frequency: u32,

    #[arg(long, short='f', default_value="2000.0")]
    carrier_frequency: f64,

    #[arg(long, short='p', default_value="0.0")]
    init_phy: f64,

    #[arg(long, short='b', default_value="32")]
    bit_ext_point_num: u16,

    #[arg(long, default_value="32")]
    bit_per_sample: u16,

    #[arg(value_enum, long, default_value="float")]
    /// Sample format, can be Float or Int
    simple_format: WavTpye
}


#[derive(Subcommand)]
enum Mode {
    /// Convert the software to mono wav audio files
    Save {
        #[arg(long, short='i', value_parser=clap::value_parser!(String))]
        input_file: String,

        #[arg(long, short='o', default_value="output.wav", value_parser=clap::value_parser!(String))]
        output_file: String,
    },
    /// Trying to decode a mono wav file
    Load {
        #[arg(long, short='l', default_value="output.wav", value_parser=clap::value_parser!(String))]
        load_file: String
    },
}

#[derive(Copy, Clone, PartialEq, Eq, PartialOrd, Ord, ValueEnum)]
enum WavTpye {
    /// Wav file with integer sample
    Int,
    /// Wav file with float sample
    Float,
}

fn main() {
    let cli = Cli::parse();
    match cli.mode {
        Mode::Save {input_file, output_file} => {
            let path = Path::new(&input_file);
            let filename = path.file_name().expect("Failed to get file name").to_str().expect("Failed to convert file name to string");

            let mut source_file_handle = File::open(&input_file).expect(format!("Failed to open file: {}", &input_file).as_str());
            let mut source_data = vec![];
            source_file_handle.read_to_end(&mut source_data).expect(format!("Failed to read file: {}", &input_file).as_str());

            let modulated_cw = toWav(filename, source_data, 32, cli.sampling_frequency, cli.carrier_frequency, cli.init_phy);

            // FIXME:
            // Only support 32bit float wav file now
            // need support other bit depth in the future
            let sf = match cli.simple_format {
                WavTpye::Int => {
                    match cli.bit_per_sample {
                        8 | 16 | 24 | 32 => SampleFormat::Int,
                        _ => {
                            let mut cmd = Cli::command();
                            cmd.error(
                                ErrorKind::ArgumentConflict,
                                "Invalid bit depth for integer sample format. Supported values are 8, 16, 24, or 32 bits."
                            ).exit();
                        },
                    }
                },
                WavTpye::Float => match cli.bit_per_sample {
                    32 => SampleFormat::Float,
                    _ => {
                        let mut cmd = Cli::command();
                        cmd.error(
                            ErrorKind::ArgumentConflict,
                            "Invalid bit depth for float sample format. Supported values are 32 bits."
                        ).exit();
                    },
                }
            };
            let spec = WavSpec {
                channels: 1,
                sample_rate: cli.sampling_frequency,
                bits_per_sample: cli.bit_per_sample,
                sample_format: sf,
            };
            let mut writer = hound::WavWriter::create(output_file, spec).expect("Failed to create WAV file");
            for sample in modulated_cw {
                writer.write_sample(sample).expect("Failed to write sample");
            }
            writer.finalize().expect("Failed to finalize WAV file");
        },
        Mode::Load {load_file} => {
            let mut reader = hound::WavReader::open(&load_file).expect(format!("Failed to open WAV file: {}", &load_file).as_str());
            let wav_data = reader.samples::<f32>()
                .map(|s| s.expect("Failed to read sample"))
                .collect::<Vec<f32>>();

            let loaded_datas = toBit(wav_data, 32, cli.sampling_frequency, cli.carrier_frequency, cli.init_phy);
            let info = getFileInfo(loaded_datas);

            println!("Find file: {}", info.file_name);
            println!("Size: {} Byte", info.data.len());
            println!("Wav Hash value: {}", info.hash_value);
            println!("local Hash value: {}", info.check_value);
            if info.hash_value == info.check_value {
                eprintln!("Hash value check pass!");
            } else {
                eprintln!("Hash value does not match the check value!");
            }

            let file_path = PathBuf::from(".\\");
            let file_path = file_path.join(info.file_name);
            let mut load_file_handle = File::create(file_path.clone()).expect(format!("Failed to create file: {}", file_path.to_str().expect("Failed to get file path")).as_str());
            load_file_handle.write_all(info.data.as_slice()).expect("Failed to write file name");
        }
    }
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn save_file() {
        let wav_data = toWav("test", vec![255, 254, 253, 253], 32, 44100, 1000.0, 0.0);
        println!("Generated WAV data length: {}", wav_data.len());
    }

    #[test]
    fn test_to_wav() {
        let data = vec![1, 2, 3, 4];
        let wav_data = toWav("test", data.clone(), 32, 44100, 1000.0, 0.0);
        assert!(!wav_data.is_empty());
    }
}