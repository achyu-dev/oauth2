export default function Home() {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-white dark:bg-black px-4">
      <h1 className="text-4xl sm:text-5xl font-bold text-gray-900 dark:text-gray-100 mb-4 text-center">
        Coming Soon
      </h1>
      <p className="text-lg sm:text-xl text-gray-600 dark:text-gray-300 mb-8 text-center max-w-xl">
        We’re working hard to bring you something amazing.
        <br />
        Stay tuned!
      </p>
      <div className="flex gap-4">
        <a
          href="https://github.com/pesu-dev/oauth2"
          target="_blank"
          rel="noopener noreferrer"
          className="rounded-full border border-gray-300 dark:border-gray-700 px-6 py-2 font-medium text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-800 transition"
        >
          Learn More
        </a>
      </div>
    </div>
  );
}
